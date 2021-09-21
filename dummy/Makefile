BUILDTOOLS = ../buildtools
ASSEMBLER = $(BUILDTOOLS)/vbcc/bin/vasmm68k_madmac
FLAGS = -m68020 -Fbin

all: clean
	mkdir build
	$(ASSEMBLER) dummy.asm -o build/dummy.bin -L build/dummy_listing.lst $(FLAGS)
	$(BUILDTOOLS)/romsplit/romsplit --input build/dummy.bin --output build/highrom.bin build/lowrom.bin --bigEndian
clean:
	if test -d "build"; then rm build/ -rf; fi
