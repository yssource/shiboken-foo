src-build:
	cd src;	qmake;	make; make install
src-clean:
	rm -fv ./src/.qmake.stash
	rm -fv ./src/Makefile
	rm -rfv ./src/obj
	rm -fv ./src/*.so*
test-build: src-clean src-build test-clean
	cd test; qmake; make; ./test
test-clean:
	rm -fv ./test/.qmake.stash
	rm -fv ./test/test
	rm -fv ./test/Makefile
	rm -rfv ./test/obj
binding-build:
	cd binding; mkdir ./build; cd build; cmake ..; make; make install; make test
binding-clean:
	cd binding; rm -rfv ./build
binding-test:
	# export LD_LIBRARY_PATH=/home/jimmy/workspace/devel/shiboken-foo/lib:${LD_LIBRARY_PATH}
	python ./binding/test/test.py
lib-clean:
	cd lib; rm -rfv ./*
all: lib-clean src-clean src-build binding-clean binding-build
	@echo 'make all'
