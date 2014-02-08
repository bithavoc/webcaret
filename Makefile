DC=dmd
OS_NAME=$(shell uname -s)
MH_NAME=$(shell uname -m)
DFLAGS=
ifeq (${DEBUG}, 1)
	DFLAGS=-debug -gc -gs -g
else
	DFLAGS=-O -release -inline -noboundscheck
endif
ifeq (${OS_NAME},Darwin)
	DFLAGS+=-L-framework -LCoreServices 
endif
lib_build_params= -I../out/di ../out/heaploop.a ../out/webcaret-router.a

build: webcaret

webcaret: lib/**/*.d deps/heaploop deps/webcaret-router
	mkdir -p out
	(cd lib; $(DC) -Hd../out/di/ -c -of../out/webcaret.o -op webcaret/*.d webcaret/http/*.d $(lib_build_params) $(DFLAGS))
	(mkdir -p out/heaploop ; cd out/heaploop/ ; ar -x ../heaploop.a)
	(mkdir -p out/webcaret-router ; cd out/webcaret-router/ ; ar -x ../webcaret-router.a)
	ar -r out/webcaret.a out/webcaret-router/*.o out/heaploop/*.o out/webcaret.o

test: webcaret
	(cd test; $(DC) -of../out/test_runner -unittest -main -op *.d -I../out/di ../out/webcaret.a $(DFLAGS))
	chmod +x out/./test_runner
	out/./test_runner

cleandeps:
	rm -rf deps/*

.PHONY: clean cleandeps

deps/heaploop:
	@echo "Compiling deps/heaploop"
	git submodule update --init --remote deps/heaploop
	rm -rf deps/heaploop/deps/duv
	rm -rf deps/heaploop/deps/events.d
	rm -rf deps/heaploop/deps/http-parser.d
	mkdir -p out
	DEBUG=${DEBUG} $(MAKE) -C deps/heaploop
	cp deps/heaploop/out/heaploop.a out/
	cp -r deps/heaploop/out/di/ out/di

deps/webcaret-router:
	@echo "Compiling deps/webcaret-router"
	git submodule update --init --remote deps/webcaret-router
	rm -rf deps/webcaret-router/deps/events.d
	mkdir -p out
	(cd deps/webcaret-router ; DEBUG=${DEBUG} $(MAKE) )
	cp deps/webcaret-router/out/webcaret-router.a out/
	cp -r deps/webcaret-router/out/di/ out/di

clean:
	rm -rf out/*
	rm -rf deps/*
