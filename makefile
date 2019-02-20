src-build:
	cd src;	qmake;	make; make install
src-clean:
	rm -fv ./src/.qmake.stash
	rm -fv ./src/Makefile
	rm -rfv ./src/obj
	rm -fv ./src/*.so*
binding-build:
	cd binding; mkdir ./build; cd build; cmake ..; make; make install; make test
binding-clean:
	cd binding; rm -rfv ./build
lib-clean:
	cd lib; rm -rfv ./*
all: lib-clean src-clean src-build binding-clean binding-build
	@echo 'make all'
