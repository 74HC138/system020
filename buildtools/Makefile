all:
	cd fsbuilder; make
	cd romsplit; make
	cd upload; make
	if ! test -f vbcc*.tar.gz; then wget http://www.ibaug.de/vbcc/vbcc_linux_x64.tar.gz; fi
	if ! test -d vbcc; then tar -xzf vbcc*.tar.gz; fi

clean:
	cd fsbuilder; make clean
	cd romsplit; make clean
	cd upload; make clean

fsbuilder:
	cd fsbuilder; make

romsplit:
	cd romsplit; make

upload:
	cd upload; make

vbcc:
	if ! test -f vbcc*.tar.gz; then wget http://www.ibaug.de/vbcc/vbcc_linux_x64.tar.gz; fi
	if ! test -d vbcc; then tar -xzf vbcc*.tar.gz; fi
