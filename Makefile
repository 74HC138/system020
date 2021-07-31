TARGET = "-m68020"
TOOLS = "$(CURDIR)/buildtools"

all:
	@echo "Build tools folder: $(TOOLS)"
clean:
	cd bios020
	make clean
	cd ../flasher020
	make clean
	cd ../minimux
	make clean
	cd ..
	@if [-d "build"]; then rm build -r; fi
	echo "all clean"
