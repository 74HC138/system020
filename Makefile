TARGET = "-m68020"
TOOLS = "$(CURDIR)/buildtools"

all:
	@echo "Build tools folder: $(TOOLS)"
	cd bios020; make

clean:
	cd bios020; make clean
	@if [-d "build"]; then rm build -r; fi
	echo "all clean"
