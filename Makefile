TARGET = "-m68020"
TOOLS = "$(CURDIR)/buildtools"

all:
	@echo "Building tools"
	cd $(TOOLS); make
	@echo "Building bios020"
	cd bios020; make

clean:
	cd $(TOOLS); make clean
	cd bios020; make clean
	@echo "all clean"

bios:
	cd bios020; make

tools:
	cd $(TOOLS); make

