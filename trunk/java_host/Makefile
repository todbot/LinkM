# Makefile for linkm library for Java -- 
#  
#

TARGET = LinkM

LIBUSBA_DIR = libusb-static
PROCESSING_LIBDIR = linkm/library


# assume macosx for ease of my develoment
ifndef OS
	OS=macosx
endif

ifeq "$(OS)" "Windows_NT"
	OS=windows
endif

#################  Mac OS X  ##################################################
ifeq "$(OS)" "macosx"
LIBTARGET = lib$(TARGET).jnilib
LIBUSBA   = libusb-macosx.a
USBFLAGS  =  -I libusb-static
USBLIBS   =  -L$(LIBUSBA_DIR)  -lusb-macosx

JAVAINCLUDEDIR = /System/Library/Frameworks/JavaVM.framework/Headers
JAVANATINC = -I $(JAVAINCLUDEDIR)/./
JAVAINCLUDE = -I $(JAVAINCLUDEDIR)

OS_CFLAGS = -g -O2 -D_BSD_SOURCE -bundle -arch i386 -arch x86_64 -std=gnu99  $(USBFLAGS)
OS_LDFLAGS =  -Wl,-search_paths_first -framework JavaVM -framework IOKit -framework CoreFoundation $(USBLIBS) 
endif

#################  Windows  ##################################################
ifeq "$(OS)" "windows"
LIBTARGET = $(TARGET).dll
LIBUSBA   = libusb-windows.a
USBLIBS   = -lhid -lsetupapi
#USBLIBS   = -lhid -lsetupapi -L$(LIBUSBA_DIR) -lusb-windows 

#JAVA_HOME = "C:\\Program Files\\Java\\jdk1.6.0_14\\"
#JAVANATINC = -I${JAVA_HOME}\include -I${JAVA_HOME}\include\win32
OS_CFLAGS  =
#OS_LDFLAGS = $(USBLIBS)
OS_LDFLAGS = -s -shared -Wl,--export-all-symbols -Wl,--kill-a $(USBLIBS)
endif

#################  Linux  ###################################################
ifeq "$(OS)" "linux"
# ???
LIBTARGET = lib$(TARGET).so  # for linux
LIBUSBA   = libusb-linux.a
USBFLAGS  = `libusb-config --cflags`
USBLIBS   =  -L$(LIBUSBA_DIR) `libusb-config --libs`
OS_CFLAGS  =
OS_LDFLAGS = $(USBLIBS)
endif


INCLUDES = -I. -I../c_host $(JAVAINCLUDE) $(JAVANATINC) 
OBJ = ../c_host/hiddata.o  ../c_host/linkm-lib.o  native$(TARGET).o 

CFLAGS  = $(OS_CFLAGS) -O -Wall -std=gnu99  $(INCLUDES)
LDFLAGS = $(OS_LDFLAGS)
CC = gcc


# FIXME: hack
all: help

help:
	@echo "This Makefile has no default rule. Use one of the following:"
	@echo "make javac ..... to build all java classes"
	@echo "make jni ....... to build JNI stubs"
	@echo "#make libprep ... to get libusb usable for compiling"
	@echo "make compile ....to build the C code" 
	@echo "make jar ....... to build the distribution jar"
	@echo "make processing. to build the processing library (only for OSX!)"
	@echo "make clean ..... to clean all built files"

javac:
	javac thingm/linkm/$(TARGET).java	

jni:
	javah -jni thingm.linkm.$(TARGET)

# the "libprep" is to pull out the libusb.a into its own dir, for static build
#libprep:
#	mkdir -p $(LIBUSBA_DIR)
#	cp `libusb-config --exec-prefix`/lib/libusb.a $(LIBUSBA_DIR)/$(LIBUSBA)

#	$(CC)  -o $(LIBTARGET) $(CFLAGS) $(LDFLAGS) $(OBJ)  -lc
compile: $(OBJ)
	$(CC)  -o $(LIBTARGET) $(CFLAGS) $(OBJ) $(LDFLAGS) 

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
	cp $(LIBTARGET) $(PROCESSING_LIBDIR)
	#cp libnativeLinkM.dll $(PROCESSING_LIBDIR)
	#cp libnativeLinkM.so $(PROCESSING_LIBDIR)
	zip -r linkm.zip linkm
	@echo
	@echo "now unzip linkm.zip into ~/Documents/Processing/libraries"
	@echo "or maybe just: cp -r linkm ~/Documents/Processing/libraries"


clean:
	rm -f thingm/linkm/*.class *.o ../c_host/*.o 
	rm -f $(LIBTARGET) thingm_linkm_$(TARGET).h
	rm -f linkm.jar linkm.zip
	rm -rf linkm



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