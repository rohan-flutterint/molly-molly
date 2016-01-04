UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S), Darwin)
	LIB_C4 = lib/c4/build/src/libc4/libc4.dylib
	LIB_Z3 = lib/z3/build/libz3.dylib
else
	LIB_C4 = lib/c4/build/src/libc4/libc4.so
	LIB_Z3 = lib/z3/build/libz3.so
endif

LIBRARY_PATH = $(shell pwd)/$(shell dirname ${LIB_C4}):$(shell pwd)/$(shell dirname ${LIB_Z3})
LD_LIBRARY_PATH = ${LIBRARY_PATH}:$(shell $$LD_LIBRARY_PATH)
DYLD_LIBRARY_PATH = ${LIBRARY_PATH}:$(shell $$DYLD_LIBRARY_PATH)

all: deps

deps: ${LIB_C4} ${LIB_Z3}

clean-deps:
	rm -rf lib/c4/build
	rm -rf lib/z3/build

lib: .gitmodules
	git submodule sync
	git submodule update --recursive --init
	touch lib

${LIB_Z3}: lib/z3 $(shell find lib/z3 -path lib/z3/build -prune -o -type f -print)
	rm -rf lib/z3/build
	cd lib/z3 && python scripts/mk_make.py --prefix=z3-dist
	cd lib/z3/build && make -j4

${LIB_C4}: lib/c4 $(shell find lib/c4 -path lib/c4/build -prune -o -type f -print)
	rm -rf lib/c4/build
	@which cmake > /dev/null
	cd lib/c4 && mkdir -p build
	cd lib/c4/build && cmake ..
	cd lib/c4/build && make

test: deps
	export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" && \
	export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}" && \
	sbt coverage test

# SBT command for running only the fast unit tests and excluding the slower
# end-to-end tests (which have been tagged using ScalaTest's `Slow` tag):
fast-test: deps
	export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}" && \
	export DYLD_LIBRARY_PATH="${DYLD_LIBRARY_PATH}" && \
	sbt coverage "testOnly * -- -l org.scalatest.tags.Slow"
