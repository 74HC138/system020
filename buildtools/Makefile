VASM_URL = http://www.ibaug.de/vbcc/vbcc_linux_x64.tar.gz

all:
	@echo "making fsbuilder"
	@cd fsbuilder; make
	@echo "making romsplit"
	@cd romsplit; make
	@echo "making upload"
	@cd upload; make
	@if ! test -f vbcc*.tar.gz; then echo "downloading vasm"; wget $(VASM_URL); fi
	@if ! test -d vbcc; then echo "uncompressing vasm"; tar -xzf vbcc*.tar.gz; fi

clean:
	@echo "cleaning tools"
	@cd fsbuilder; make clean
	@cd romsplit; make clean
	@cd upload; make clean
	@echo "tools clean"

fsbuilder:
	@echo "making fsbuilder"
	@cd fsbuilder; make

romsplit:
	@echo "making romsplit"
	@cd romsplit; make

upload:
	@echo "making upload"
	@cd upload; make

vasm:
	@echo "making vasm"
	@if ! test -f vbcc*.tar.gz; then echo "donwloading vasm"; wget $(VASM_URL); fi
	@if ! test -d vbcc; then echo "uncompressing vasm"; tar -xzf vbcc*.tar.gz; fi

#$(V).SILENT:
