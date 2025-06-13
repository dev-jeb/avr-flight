# Assembler and Assembler flags
AS = avr-as
ASFLAGS = -g -mmcu=atmega328p

# match any files in the common directory
OBJ_FILES = crt.o

# Targets
all: $(OBJ_FILES)

$crt.o: crt.s 
	$(AS) $(ASFLAGS)  -c $< -o $@

clean:
	rm -rf crt.o

.PHONY: all clean
