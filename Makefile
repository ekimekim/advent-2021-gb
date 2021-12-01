
# avoid implicit rules for clarity
.SUFFIXES:
.PHONY: bgb clean debug tests testroms

ASMS := $(wildcard *.asm)
OBJS := $(ASMS:.asm=.o)
DEBUGOBJS := $(addprefix build/debug/,$(OBJS))
RELEASEOBJS := $(addprefix build/release/,$(OBJS))
INCLUDES := $(wildcard include/*.asm)
ASSETS := $(shell find assets/ -type f)
TESTS := $(wildcard tests/*.py)
TASKS := $(wildcard tasks/*.asm)
ROMS := $(TASKS:.asm=.gb)
FIXARGS := -C

all: $(addprefix build/release/,$(ROMS))
debug: $(addprefix build/debug/,$(ROMS))

tests/.uptodate: $(TESTS) tools/unit_test_gen.py $(DEBUGOBJS)
	python tools/unit_test_gen.py .
	touch "$@"

testroms: tests/.uptodate

tests: testroms
	tools/runtests

include/inputs/test.asm: include/inputs
	echo "db 50, 48, 50, 49, 10, 102, 111, 111, 10" > $@

include/inputs/%.asm: tools/get_input.py .cookie include/inputs
	python tools/get_input.py $@

include/assets/.uptodate: $(ASSETS) tools/assets_to_asm.py
	python tools/assets_to_asm.py assets/ include/assets/
	touch $@

build/debug/%.o: %.asm $(INCLUDES) include/assets/.uptodate build/debug
	rgbasm -DDEBUG=1 -i include/ -v -o $@ $<

build/release/%.o: %.asm $(INCLUDES) include/assets/.uptodate build/release
	rgbasm -DDEBUG=0 -i include/ -v -o $@ $<

build/debug/tasks/%.gb: build/debug/tasks/%.o $(DEBUGOBJS)
# note padding with 0x40 = ld b, b = BGB breakpoint
	rgblink -n $(@:.gb=.sym) -o $@ -p 0x40 $^
	rgbfix -v -p 0x40 $(FIXARGS) $@

build/release/tasks/%.gb: build/release/tasks/%.o $(RELEASEOBJS)
	rgblink -n $(@:.gb=.sym) -o $@ $^
	rgbfix -v -p 0 $(FIXARGS) $@

build/debug build/release build/debug/tasks build/release/tasks include/inputs:
	mkdir -p $@

clean:
	rm -f build/*/*.o build/*/tasks/*.sym build/*/tasks/*.gb include/assets/.uptodate include/assets/*.asm tests/*/*.{asm,o,sym,gb}
