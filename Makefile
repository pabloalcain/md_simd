.PHONY: default help object executable all clean
CC = gcc
ASM = nasm

ASM_FLAGS = -felf64 -Fdwarf -g
CC_FLAGS = -g -std=gnu99 -O0 -pg
LD_FLAGS = -lm -pg

LD = $(CC)

SOURCE_C = $(wildcard *.c)
OBJECTS_C = $(patsubst %.c, %_c.o, $(SOURCE_C))
SOURCE_S = $(wildcard *.asm)
OBJECTS_S = $(patsubst %.asm, %_asm.o, $(SOURCE_S))

EXECUTABLE = md_c.e md_asm.e

default: all

objects: $(OBJECTS_C) $(OBJECTS_S)

executable: $(EXECUTABLE)

all: objects executable

%_asm.o: %.asm
	$(ASM) $(ASM_FLAGS) $^ -o $@

%_c.o: %.c
	$(CC) $(CC_FLAGS) -c $^ -o $@

md_c.e: newton_c.o md_c.o
	$(LD) $^ $(LD_FLAGS) -o $@

md_asm.e: newton_asm.o md_c.o
	$(LD) $^ $(LD_FLAGS) -o $@

clean:
	rm -rfv $(OBJECTS_C) $(OBJECTS_S) $(EXECUTABLE)
