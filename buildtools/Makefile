VASM_URL = http://www.ibaug.de/vbcc/vbcc_linux_x64.tar.gz

all: fsbuilder romsplit upload vasm
	@echo "buildtools fully build"

clean:
	@echo "cleaning tools"
	@cd fsbuilder; make clean
	@cd romsplit; make clean
	@cd upload; make clean
	@echo "tools clean"

fsbuilder:
	@echo "making fsbuilder"
	@cd fsbuilder; make

romsplit: git
	@echo "making romsplit"
	@cd romsplit; make

upload:
	@echo "making upload"
	@cd upload; make

vasm:
	@echo "making vasm"
	@if ! test -f vbcc*.tar.gz; then echo "donwloading vasm"; wget $(VASM_URL); fi
	@if ! test -d vbcc; then echo "uncompressing vasm"; tar -xzf vbcc*.tar.gz; fi

git:
	@if ! test -d romsplit; then git clone https://github.com/74HC138/romsplit.git; fi

#$(V).SILENT:
