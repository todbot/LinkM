
TARGET = LinkM
LIBTARGET = libnative$(TARGET)
PROCESSING_LIBDIR = linkm/library
LIBUSBA_DIR = libusb-static

# Use the following 3 lines on Unix and Mac OS X:
USBFLAGS = `libusb-config --cflags`
USBLIBS =  -L$(LIBUSBA_DIR) `libusb-config --libs`
EXE_SUFFIX=

# for Mac OS X
JAVAINCLUDEDIR = /System/Library/Frameworks/JavaVM.framework/Headers
JAVANATINC = -I $(JAVAINCLUDEDIR)/./
JAVAINCLUDE = -I $(JAVAINCLUDEDIR)

INCLUDES = -I . -I../c_host $(JAVAINCLUDE) $(JAVANATINC) 
CFLAGS = -g -O2 -D_BSD_SOURCE -bundle  -std=gnu99 $(USBFLAGS) $(INCLUDES)
#CFLAGS = -g -O2 -D_BSD_SOURCE -bundle  -arch i386 -arch ppc -std=gnu99 $(USBFLAGS) $(INCLUDES)
LDFLAGS =  -Wl,-search_paths_first -framework JavaVM -framework IOKit -framework CoreFoundation $(USBLIBS) 

OBJ=	../c_host/hiddata.o  ../c_host/linkm-lib.o  native$(TARGET).o 

CC = gcc

# FIXME: hack
all: help

help:
	@echo "This Makefile has no default rule. Use one of the following:"
	@echo "make javac ..... to build all java classes"
	@echo "make jni ....... to build JNI stubs"
	@echo "make libprep ... to get libusb usable for compiling"
	@echo "make compile ....to build the C code" 
	@echo "make jar ....... to build the distribution jar"
	@echo "make processing. to build the processing library"
	@echo "make clean ..... to clean all built files"

javac:
	javac thingm/linkm/$(TARGET).java	

jni:
	javah -jni thingm.linkm.$(TARGET)

# these three steps should be run on each platform, others can be done once
# the "libprep" is to pull out the libusb.a into its own dir, for static build
libprep:
	mkdir -p $(LIBUSBA_DIR)
	cp `libusb-config --exec-prefix`/lib/libusb.a $(LIBUSBA_DIR)

compile: $(OBJ)
	$(CC)  -o $(LIBTARGET).jnilib $(CFLAGS) $(LDFLAGS) $(OBJ)  -lc

.c.o:
	$(CC) $(ARCH_COMPILE) $(CFLAGS) -c $*.c -o $*.o

# packaging
jar: javac jni compile
	jar -cfm linkm.jar  packaging/Manifest.txt thingm/linkm/*.class

processing: processinglib
processinglib:	jar
	rm -f linkm.zip
	mkdir -p $(PROCESSING_LIBDIR)
	cp packaging/processing-export.txt $(PROCESSING_LIBDIR)/export.txt
	cp linkm.jar $(PROCESSING_LIBDIR)
	cp libnativeLinkM.jnilib $(PROCESSING_LIBDIR)
	zip -r linkm.zip linkm
# now unzip linkm.zip into ~/Documents/Processing/libraries  or maybe


clean:
	rm -f thingm/linkm/*.class *.o *.jnilib thingm_linkm_$(TARGET).h
	rm -f linkm.jar linkm.zip
	rm -rf linkm
	rm -rf $(LIBUSBA_DIR)



#     -I /export/home/jdk1.2/include 
#     -I/export/home/jdk1.2/include/linux nativelib.c  
#     -static -lc

# see:
# http://macosx.com/forums/mac-os-x-system-mac-software/277799-problem-c-dynamic-library-jni.html
#
# for Linux
#
# In Linux the following options worked
# compiler:
#  gcc -Wall -O3 -c -I${JAVA_HOME}/include -I${JAVA_HOME}/include/win32
# linker:
#  gcc -s -shared

# for Windows
# In Windows the following options worked
# compiler:
#  gcc -Wall -O3 -c -I${JAVA_HOME}\include -I${JAVA_HOME}\include\win32
# linker:
#  gcc -s -shared -Wl,--export-all-symbols -Wl,--kill-a


# 
# os x: use "otool -L blah.jnilib" to find shared lib dependencies
# linux: use "ldd blah.so" to do the same
# windows:  ??? no clue, maybe "DLL Show" by Greg Braun (but only for running)


# 
# NOTE: to statically link libusb on Mac OS X, use the "-Wl,-search_paths_first"
# linker option and point to a directory that contains *only* the libusb.a file.
# The standard libusb libs contain a .dylib and .a, and the dylib will get 
# picked up first.
#