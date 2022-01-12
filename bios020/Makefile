BUILDTOOLS = ../buildtools
ASSEMBLER = $(BUILDTOOLS)/vbcc/bin/vasmm68k_madmac
FLAGS = -m68020 -Fbin
FSSIZE = 0

all: clean prepare payload fs
	@echo ----------------------------------------------------------------------
	@echo Building ROM
	$(ASSEMBLER) source/main.asm -o build/bios.bin -L build/bios_listing.lst $(FLAGS)
	@echo Building ROM DONE
	@echo Splitting ROM
	$(BUILDTOOLS)/romsplit/romsplit --input build/bios.bin --output build/highrom.bin build/lowrom.bin --bigEndian
	@echo Splitting ROM DONE
	@echo ----------------------------------------------------------------------

payload: prepare
	@echo ----------------------------------------------------------------------
	@echo Building payload
	$(ASSEMBLER) source/updaterPayload.asm -o build/updaterPayload.bin -L build/updaterPayload_listing.lst $(FLAGS) -pic
	@echo Building payload DONE

prepare:
	if ! test -d "build"; then mkdir build; fi

debug: clean
	mkdir build
	$(ASSEMBLER) source/debug.asm -o build/debug.bin -L build/debug_listing.lst $(FLAGS)
	$(BUILDTOOLS)/romsplit/romsplit --input build/debug.bin --output build/dbromhigh.bin build/dbromlow.bin --bigEndian

fs:
	@echo "Building romfs"
	$(BUILDTOOLS)/fsbuilder/buildfs.sh $(FSSIZE) romfs/romfs.bin romfs/fsdata

clean:
	if test -d "build"; then rm build/ -rf; fi

#$(V).SILENT:
