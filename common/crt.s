    /**
    * @contact_info:
    * Author: dev_jeb
    * Email: developer_jeb@outlook.com
    *
    * @purpose
    * The routines found in this file put the microcontroller into
    * the state expected by the main function. Normally these routines
    * are provided by the toolchain and are by default included at link
    * time. However, we are going to do everything on our own. In the makefile 
    *  of our examples/lessons/projects we are passing the options 
    * -nostartfiles, -nostdlib, and -nodefaultlibs to the linker. 
    * This ensures that the toolchain provided routines are not 
    * included in the final executable and instead our linker script
    * (default.ld) uses our implementation (this file) of these routines.
    **/

    /**
    * This macro is used to define the vectors (minus reset vector) in 
    * the vector table. The name passed to the macro is defined in the
    * relocatable object file (crt.o) as a weak symbol. The linker treats 
    * weak symbols specially. If the weak symbol is defined anywhere in
    * in the set of included object files and is not weak, the linker will
    * resolve the symbols runtime address to point to that definition. If the 
    * weak symbol is not defined in the set of included object files the linker
    * will resolve the symbols runtime address to point to the symbol defined
    * in the macro. In this case the weak symbol will point to 
    * the symbol __bad_interrupt.
    **/
    .macro  vector name
    .weak   \name
    .set    \name, __bad_interrupt
    jmp    \name
    .endm
	
    /**
    * @vector_table
    * This is the vector table. It will be placed in the .vectors section 
    * of the relocatable object file (crt.o). In the linker script (default.ld) 
    * we will place this section at the start of flash as is expected by the
    * hardware. This is a data structure used by the microcontroller to handle
    * interrupts. The microcontroller has a finite and defined set of interrupts.
    * Each interrupt has an entry in the vector table. When one of the interrupts occur
    * the microcontroller will jump to the vector table and execute the command
    * at that predefined location. This happens to be a jump command to the interrupt
    * handler defined by you guessed it ... our weak symbols we have talked so much about.
    * This gives us a way to control what the microcontroller does when a specific interrupt 
    * occurs. From the description of the macro above how would a user define a handler for 
    * a specific interrupt? You would define a function with the same name as the weak
    * symbol for that specific interrupt in the vector table. For example we could
    * define a function to be called when external interrupt 0 occurs (__vector_1)
    * by defining the function
    *                  
    *    void __vector_1(void) 
    *    { 
    *     ...
    *    } 
    *
    * Because the symbol __vector_1 defined by the function is a strong symbol, the linker 
    * will resolve the runtime address of the interrupt handler to our function. 
    *
    * vector tables like this are used to implement the interrupt infrastructure of
    * many different microcontrollers. The implementation details will differ but the
    * concept is the same.
    **/
    .section .vectors,"ax",@progbits
	.global __vectors
	.func   __vectors
__vectors:
	jmp    __init
	vector  __vector_1 ;notice how we use the macro defined above.
	vector  __vector_2
	vector  __vector_3
	vector  __vector_4
	vector  __vector_5
    vector  __vector_6
    vector  __vector_7
    vector  __vector_8
    vector  __vector_9
    vector  __vector_10
    vector  __vector_11
    vector  __vector_12
    vector  __vector_13
    vector  __vector_14
    vector  __vector_15
    vector  __vector_16
    vector  __vector_17
    vector  __vector_18
    vector  __vector_19
    vector  __vector_20
    vector  __vector_21
    vector  __vector_22
    vector  __vector_23
    vector  __vector_24
    vector  __vector_25
    .endfunc

    /**
    * This is the default interrupt handler. Remember that all the vectors
    * in the vector table other then the reset vector were defined as weak symbols
    * that would be redirected to this handler if not defined by the user.
    * This handler is also defined as a weak symbol. Therefore, if the user
    * defines __vector_default, they could control what happens when an interrupt
    * occurs. Here, I make a design decision. In the default case we will jump to the 
    * reset vector. You could do whatever you like.
    **/
    .section .bad_interrupt,"ax",@progbits
    .global __bad_interrupt
    .func   __bad_interrupt
__bad_interrupt:
    .weak __vector_default
    .set __vector_default, __vectors
    jmp __vector_default
    .endfunc

    /**
    * So on reset or bad interrupt which jumps to reset we will jump to the __init symbol. 
    * What should we do from here? The objective of this file is to call our main function.
    * Doing this means we will setup the environment that our main function expects.
    * We will zero out the (r1) register as expected by compiler. 
    * We will also zero out the status register. We will set the stack register to 0x08FF 
    * which is the top of SRAM. The stack register is implemented as (2) 8-bit registers 
    * in the AVR architecture. This can be seen in the datasheet. That means moving the top
    * 8 bits of the stack pointer into the high byte of the stack pointer register and the
    * bottom 8 bits into the low byte of the stack pointer register.
    **/
    .section .init,"ax",@progbits
    .weak __init
    .func __init
__init:
    clr r1        ;set the zero register to zero
    out 0x3F, r1  ;zero out the status register
    ldi r28, 0x08
    out 0x3E, r28 ;set stack pointer high byte
    ldi r28, 0xFF
    out 0x3D, r28 ;set stack pointer low byte
    rjmp __load_data
    .endfunc

    /**
    * The main function expects the data defined by the program located in the .data section
    * of the executable object file to be located in SRAM. It is then our job to copy this data
    * from the flash memory to the SRAM before we call the main function. 
    **/
    .section .load_data,"aw",@progbits
    .global __load_data
    .func __load_data
__load_data:
    /**
    * I would like to take a moment to point out the importance of what we are doing here.
    * Registers 26-31 are used as pointer registers. You load the high byte into one. The
    * low byte in the other (high and low specified in datasheet) and use [lpm] to access
    * the data in flash. Notice how we increment the Z pointer with Z+. Next we store the
    * data loaded into r0 into the SRAM pointed to by the Y pointer. This is an example of
    * a useful addressing mode.
    **/
    ldi r17, hi8(__data_end_sram)    ;r17     <-- high byte of (uint8_t*)__data_end_sram
    ldi r30, lo8(__data_start_flash) ;low(Z)  <-- low byte of (uint8_t*)__data_start_flash
    ldi r31, hi8(__data_start_flash) ;high(Z) <-- high byte of (uint8_t*)__data_start_flash
    ldi r28 , lo8(__data_start_sram) ;low(Y)  <-- low byte of (uint8_t*)__data_start_sram
    ldi r29 , hi8(__data_start_sram) ;high(Y) <-- high byte of (uint8_t*)__data_start_sram
    rjmp __load_data_start
    .endfunc
    /**
    * next we load a byte from flash (.data byte) at [Z pointer] into r0 and 
    * increment Z. We will store the value [r0] into the SRAM, at location Y.
    **/
    .func __load_data_loop
__load_data_loop:
    lpm r0, Z+ ;load the byte from flash
    st Y+, r0  ;store the byte in sram
    /**
    * next we need to check if we have reached the end of the .data section. We will do
    * this by comparing the Z pointer to the end of the .data section. If we have not 
    * reached the end of the .data section we will loop back and load the next byte from 
    * flash into r0 and store it in SRAM. 
    **/
__load_data_start:
    cpi  r28, lo8(__data_end_sram)
    cpc r17, r29
    brne __load_data_loop
    .endfunc

    /**
    * n bytes must be allocated in SRAM for the .bss where n = SIZEOF(.bss). These allocated bytes must be 
    * initialized to zero. The .bss section contains the uninitialized global and static variables 
    * (e.g uint8_t value). 
    **/
    .section .zero_bss,"aw",@progbits
    .global __zero_bss
    .func __zero_bss
__zero_bss:
    ldi r30, lo8(__bss_start_sram) ;set Z pointer low byte to the low byte of ADDR(.bss section)
    ldi r31, hi8(__bss_start_sram) ;set Z pointer high byte to the high byte of ADDR(.bss section)
    ldi r28, lo8(__bss_end_sram)   ;set Y pointer low byte to the low byte of ADDR(__bss_end)
    ldi r29, hi8(__bss_end_sram)   ;set Y pointer high byte to the high byte of ADDR(__bss_end)
__zero_bss_loop:
    cpi r30, lo8(__bss_end_sram)   ;compare the low byte of Z to the low byte of ADDR(__bss_end)
    cpc r31, r29                   ;compare with carry the high byte of Z to the high byte of ADDR(__bss_end)
    breq __zero_bss_end            ;if they are equal jump to end of function
    st Z+, r0                      ;store zero in the SRAM pointed to by Z and increment Z
    jmp __zero_bss_loop            ;loop back
__zero_bss_end:
    rjmp __call_main               ;jump to the main function
    .endfunc

    /**
    * with every thing setup we can now call the main function. First we should
    * clear the status register.
    **/
    .section .call_main,"ax",@progbits
    .global __call_main
    .func __call_main
__call_main:
    out 0x3F, r1 ;clear the status register
    sei          ;enable interrupts
    call main    ;call the main function
    cli          ;disable interrupts
    rjmp __exit   ;jump to the exit function
    .endfunc

    .global __exit
    .func __exit
__exit:
    jmp __exit   ;loop after main return
    .endfunc

    /**
    * This section is used to define the version of crt.s. We will ensure in the linker script
    * that we catch this section and include it in the final executable. This is a simple way to
    * include some version control. Notice that this is a global symbol. We can reference this
    * symbol in our C program. We could write a function that prints this version string.
    **/
    .section .crt_version,"S",@progbits
    .global __crt_version_string
__crt_version_string:
    .string  "Version 1.1.3"
    .byte(0)
    


    /**
    * Version 1.1.2: Added __F_CPU symbol to define the clock frequency.
    * Version 1.1.3: Removed __F_CPU symbol. Fixed all hanging functions. 
    * hanging defined as relied on placment in executable to ensure proper
    * program flow. Now all functions explicitly call the next function.
    **/

