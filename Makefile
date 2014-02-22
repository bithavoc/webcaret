DC=dmd
OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)
DFLAGS=
ARCH=`uname -m`
OS_TYPE=linux
ifeq (${DEBUG}, 1)
	DFLAGS=-debug -gc -gs -g
else
	DFLAGS=-O -release -inline -noboundscheck
endif
ifeq (${OS_NAME},Darwin)
	DFLAGS+=-L-framework -LCoreServices 
	OS_TYPE=osx
endif
lib_build_params= -I../out/di ../out/heaploop.a ../out/webcaret-router.a

build: webcaret

dub: webcaret
	mkdir -p dub/bin
	mkdir -p dub/di
	cp -r out/di/ dub/di/
	cp out/webcaret.a dub/bin/webcaret-$(OS_TYPE)-$(ARCH).a

webcaret: lib/**/*.d deps/heaploop deps/webcaret-router
	mkdir -p out
	(cd lib; $(DC) -Hd../out/di/ -c -of../out/webcaret.o -op webcaret/*.d $(lib_build_params) $(DFLAGS))
	(mkdir -p out/heaploop ; cd out/heaploop/ ; ar -x ../heaploop.a)
	(mkdir -p out/webcaret-router ; cd out/webcaret-router/ ; ar -x ../webcaret-router.a)
	ar -r out/webcaret.a out/webcaret-router/*.o out/heaploop/*.o out/webcaret.o

test: webcaret
	(cd test; $(DC) -of../out/test_runner -unittest -main -op *.d -I../out/di ../out/webcaret.a $(DFLAGS))
	chmod +x out/./test_runner
	out/./test_runner

cleandeps:
	rm -rf deps/*

.PHONY: clean cleandeps webcaret

deps/heaploop:
	@echo "Compiling deps/heaploop"
	git submodule update --init deps/heaploop
	(cd deps/heaploop; git checkout master)
	(cd deps/heaploop; git pull origin master)
	mkdir -p out
	DEBUG=${DEBUG} $(MAKE) -C deps/heaploop clean
	DEBUG=${DEBUG} $(MAKE) -C deps/heaploop
	cp deps/heaploop/out/heaploop.a out/
	cp -r deps/heaploop/out/di/ out/di

deps/webcaret-router:
	@echo "Compiling deps/webcaret-router"
	git submodule update --init deps/webcaret-router
	(cd deps/webcaret-router; git checkout master)
	(cd deps/webcaret-router; git pull origin master)
	rm -rf deps/webcaret-router/deps/events.d
	mkdir -p out
	(cd deps/webcaret-router ; DEBUG=${DEBUG} $(MAKE) clean )
	(cd deps/webcaret-router ; DEBUG=${DEBUG} $(MAKE) )
	cp deps/webcaret-router/out/webcaret-router.a out/
	cp -R deps/webcaret-router/out/di/* out/di

clean:
	rm -rf out/*
	rm -rf deps/*
