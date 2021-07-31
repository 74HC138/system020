BUILDTOOLS = ../buildtools
ASSEMBLER = $(BUILDTOOLS)/vbcc/bin/vasmm68k_madmac
FLAGS = -m68020 -Fbin

all: clean
	mkdir build
	$(ASSEMBLER) source/main.asm -o build/bios.bin -L build/bios_listing.lst $(FLAGS)
	$(BUILDTOOLS)/romsplit/romsplit --input build/bios.bin --output build/highrom.bin build/lowrom.bin --bigEndian

debug: clean
	mkdir build
	$(ASSEMBLER) source/debug.asm -o build/debug.bin -L build/debug_listing.lst $(FLAGS)
	$(BUILDTOOLS)/romsplit/romsplit --input build/debug.bin --output build/dbromhigh.bin build/dbromlow.bin --bigEndian
clean:
	if test -d "build"; then rm build/ -rf; fi
