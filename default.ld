/**
* @contact_info:
* Author: dev_jeb
* Email: developer_jeb@outlook.com
*
* @purpose:
* A linker script to use with avr-ld.
**/

/**
* These statements will tell the linker to add certain metadata to the 
* headers in the executable file. The executable will be the elf32-avr format.
* The elf headers will contain metadata relating to the ATmega328p.
**/
OUTPUT_FORMAT("elf32-avr","elf32-avr","elf32-avr")
OUTPUT_ARCH(avr:5)

/**
* we will explicitly link with the crt.o file found in the 
* /common/ directory (We need this to setup the environment prior to calling main). 
* Notice how we pass the option -L with the path to the common directory in the makefile. 
* The linker searches for the crt.o file in the current directory then when not found traverses 
* the directories specified with the -L option.
* 
* @note:
* if you are getting a linker error where this file can not be found ensure you have built
* the crt.o file in the common directory. You can do this by running the make command in the
* common directory.
**/
INPUT (crt.o)

/** 
* define the memory layout of the ATmega328p 
**/
MEMORY
{
  FLASH            (rx)  : ORIGIN = 0x000000, LENGTH = 32K
  SRAM            (rw!x) : ORIGIN = 0x800100, LENGTH = 2K
  EEPROM          (rw!x) : ORIGIN = 0x810000, LENGTH = 1K
  FUSE            (rw!x) : ORIGIN = 0x820000, LENGTH = 1K
  LOCK            (rw!x) : ORIGIN = 0x830000, LENGTH = 1K
  SIGNATURE       (rw!x) : ORIGIN = 0x840000, LENGTH = 1K
  USER_SIGNATURES (rw!x) : ORIGIN = 0x850000, LENGTH = 1K
}

SECTIONS
{

    .text : 
    {

        /**
        * must place the reset vector at the beginning of the .text section
        **/
        crt.o(.vectors)
        KEEP(crt.o(.vectors))

        /**
        * section contains the function that will be called by the reset vector
        * sets status register to 0 and initialize the stack pointer
        **/
        crt.o(.bad_interrupt)
        KEEP(crt.o(.bad_interrupt))
        
        /** 
        * section contains weak symbol for __init that will ensure reset vector 
        * jumps to __init function if it is not redefined by the user. __init is 
        * defined in crt.s
        **/
        crt.o(.init)
        KEEP(crt.o(.init))

        /**
        * section that contains the routines to load the data section from flash to ram
        * and to zero out the bss section
        **/
        crt.o(.load_data)
        KEEP(crt.o(.load_data))

        /**
        * section that contains the routines to zero out the bss section
        **/
        crt.o(.zero_bss)
        KEEP(crt.o(.zero_bss))

        /**
        * section that contains the routines to call the main function and
        * loop indefinitely if main returns
        **/
        crt.o(.call_main)
        KEEP(crt.o(.call_main))

        main.o(.text)
        main.o(.text.*)

        /**
        * if object files are included (other than main.o) we will include the text sections here.
        * We could also get rid of the main.o wildcards above and accumulate all the text sections here.
        **/
        *(.text)

        /**
        * Here we will include the .rodata section. This section contains read only data 
        * that lives only in flash.
        **/
        *(.rodata)
        *(.rodata.*)
        KEEP(*(.rodata))

        /**
        * include the version information for crt.s
        **/
        crt.o(.crt_version)
        KEEP(crt.o(.crt_version))

        . = ALIGN(2);
        _text_end = .;
    }> FLASH

    /**
    * The AT(ADDR(.program) + SIZEOF (.program)) described the load address of the .data section.
    * This is where the .data section will be placed in flash. However the virtual memory address
    * will be the ORIGIN defined by the MEMORY directive above.
    **/
    .data : AT (ADDR(.text) + SIZEOF (.text)) 
    {
        /**
        * __data_start_sram will be the offset into the .data section from the virtual
        * memory address (0x800100) therefore this is the start address of data in sram.
        * same logic applies to __data_end_sram.
        **/
        __data_start_sram = .;
        *(.data)
        . = ALIGN(2);
        __data_end_sram = .;
    }> SRAM

    .bss : 
    {
        __bss_start_sram = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        __bss_end_sram = .;
    }> SRAM
    __HEAP_START = .;

    /**
    * here __data_load_start refers to the load address (its address in flash) of the
    * .data section. We can see from the above that the .data section is defined with a load
    * address of ADDR(.text) + SIZEOF(.text) where ADDR(.text) = 0x0000 in flash
    * (see memory layout at the top of this file) and SIZEOF(.text) is defined by linker 
    * after the sizes of all sections placed in the .text section are known.
    *
    * __data_load_end is the end address (byte after the last data byte) of the .data section in flash.
    **/
    __data_start_flash = LOADADDR(.data);
    __data_end_flash = __data_start_flash + SIZEOF(.data);
    __data_bytes_to_read = SIZEOF(.data);
    __bss_bytes_to_clear = SIZEOF(.bss);
}

