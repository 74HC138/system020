BUILDTOOLS = ../buildtools
ASSEMBLER = $(BUILDTOOLS)/vbcc/bin/vasmm68k_madmac
FLAGS = -m68020 -Fbin
FSSIZE = 256

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
	@echo Building romfs
	if test -d "romfs.bin"; then rm romfs.bin; fi
	touch romfs.bin
	dd if=/dev/zero count=$(FSSIZE) of=romfs.bin
	mkfs -t fat -F 12 romfs.bin
	mkdir romfs_mount
	mount -o loop romfs.bin romfs_mount/
	cp -r romfs/* romfs_mount/
	umount romfs_mount
	rm romfs_mount -r

clean:
	if test -d "build"; then rm build/ -rf; fi

$(V).SILENT:
