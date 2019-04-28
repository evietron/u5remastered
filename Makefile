# Settings
TARGET=c64
CL65=cl65
#CA65=ca65
#LD65=ld65
CL65FLAGS=-t $(TARGET) -I ./src/include
#CA65FLAGS=-t $(TARGET) -I . -I ./src/include --debug-info
#LD65FLAGS=

.SUFFIXES: .prg .s

# ultima 5
ultima5: build/u5remastered.crt

# all
all: build/obj/directory.data.prg build/obj/files.data.prg code build/u5remastered.crt

# code
code: build/obj/exodecrunch.prg build/obj/loader.prg build/obj/initialize.prg build/obj/io.prg

# compile
%.o: %.s
	$(CA65) $(CA65FLAGS) -o $@ $<

# builddir
#builddirs:
#	mkdir -p build/obj build/files build/temp
	
# loader
#src/ef/loader.o:  src/ef/loader.s

# initialize
#src/ef/initialize.o:  src/ef/initialize.s

# loader.prg
build/obj/loader.prg: src/ef/loader.s
	$(CL65) $(CL65FLAGS) -o $@ -C $(<D)/$(*F).cfg $^

# initialize
build/obj/initialize.prg: src/ef/initialize.s
	$(CL65) $(CL65FLAGS) -o $@ -C $(<D)/$(*F).cfg $^

# io
build/obj/io.prg src/io/io.map: src/io/io.s src/io/get_crunched_byte.s
	$(CL65) $(CL65FLAGS) -vm -m $(<D)/io.map -o $@ -C $(<D)/$(*F).cfg $^

# exomizer
build/obj/exodecrunch.prg: src/exo/exodecrunch.s
	$(CL65) $(CL65FLAGS) -vm -m $(<D)/exodecrunch.map -o $@ -C $(<D)/$(*F).cfg $^

# io jump table replacements
# ### todo ###

# raw files
build/files/files.list:
	mkdir -p ./build/files ./build/obj
	c1541 disks/osi.d64 -read temp.subs build/obj/temp.subs.prg
	tools/extract.py -v -s ./disks -b ./build

# crunched
build/files/crunched.done: build/files/files.list
	tools/crunch.py -v -b ./build

# build efs
build/obj/directory.data.prg build/obj/files.data.prg: build/files/crunched.done
	tools/mkefs.py -v -s ./src -b ./build

# cartridge binary
build/obj/u5remastered.bin: build/obj/directory.data.prg build/obj/files.data.prg build/obj/exodecrunch.prg build/obj/initialize.prg build/obj/loader.prg src/ef/eapi-am29f040.prg build/obj/io.prg build/obj/exodecrunch.prg
	tools/mkbin.py -v -s ./src/ -b ./build/

# cartdridge crt
build/u5remastered.crt: build/obj/u5remastered.bin
	cartconv -t easy -o build/u5remastered.crt -i build/obj/u5remastered.bin -n "Ultima 5 Remastered Demo" -p

