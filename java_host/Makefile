# Makefile for linkm library for Java -- 
#  
# This makefile builds Java and native code for multiple OSes
# To build the multi-platform Processing library, it's assumed that
# this directory is shared between a Mac OS X, Windows, and Linux computer
#
# Assumptions:
# Mac OS X is at least 10.6 (Snow Leopard)
# Windows is at least Windows XP with MinGW and MinSys installed
# Linux is Ubuntu 9 or above
#
# Attempts are made to make universal binary (i386 & x86_64) on Mac OS X
#
#

TARGET = LinkM

LIBUSBA_DIR = libusb-static
#PROCESSING_LIBDIR = linkm/library


# try to do some autodetecting
UNAME := $(shell uname -s)

ifeq "$(UNAME)" "Darwin"
	OS=macosx
endif

ifeq "$(OS)" "Windows_NT"
	OS=windows
endif

ifeq "$(UNAME)" "Linux"
	OS=linux
endif


#################  Mac OS X  ##################################################
ifeq "$(OS)" "macosx"
JAVA_HOME:=/System/Library/Frameworks/JavaVM.framework/Versions/1.5.0/Home
PATH:=$(JAVA_HOME)/bin:$(PATH)

LIBTARGET = lib$(TARGET).jnilib
#LIBUSBA   = libusb-macosx.a
#USBLIBS   =  -L$(LIBUSBA_DIR)  -lusb-macosx
USBFLAGS  =  `libusb-legacy-config --cflags`
USBLIBS   = /opt/local/lib/libusb-legacy/libusb.a

JAVAINCLUDEDIR = /System/Library/Frameworks/JavaVM.framework/Headers
JAVANATINC = -I $(JAVAINCLUDEDIR)/./
JAVAINCLUDE = -I $(JAVAINCLUDEDIR)

OS_CFLAGS = -g -O2 -D_BSD_SOURCE -bundle -arch i386 -arch x86_64 -arch ppc -std=gnu99  $(USBFLAGS) 
OS_CFLAGS += -isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5
#OS_CFLAGS = -g -O2 -D_BSD_SOURCE -bundle -arch i386 -arch x86_64 -arch ppc -std=gnu99  $(USBFLAGS)
#OS_CFLAGS = -g -O2 -D_BSD_SOURCE -bundle -arch i386 -arch x86_64 -std=gnu99  $(USBFLAGS)
OS_LDFLAGS =  -Wl,-search_paths_first -framework JavaVM -framework IOKit -framework CoreFoundation $(USBLIBS) 
endif

#################  Windows  ##################################################
ifeq "$(OS)" "windows"
LIBTARGET = $(TARGET).dll
LIBUSBA   = libusb-windows.a
USBLIBS   = -lhid -lsetupapi

# this must match your Java install
JAVA_HOME = "C:\\Program Files\\Java\\jdk1.6.0_20\\"
JAVA_NATIVE_INC = -I${JAVA_HOME}/include -I${JAVA_HOME}/include/win32
OS_CFLAGS  = ${JAVA_NATIVE_INC}
OS_LDFLAGS = -s -shared -Wl,--export-all-symbols -Wl,--kill-a $(USBLIBS)
endif

#################  Linux  ###################################################
ifeq "$(OS)" "linux"
# ???
LIBTARGET = lib$(TARGET).so  # for linux
#LIBUSBA   = libusb-linux.a
USBFLAGS  = `libusb-config --cflags`
USBLIBS   = `libusb-config --libs`
#USBLIBS   =  -L$(LIBUSBA_DIR) -lusb-linux
OS_CFLAGS  = $(USBFLAGS) -shared -I/usr/lib/jvm/java-6-sun/include -I/usr/lib/jvm/java-6-sun/include/linux
OS_LDFLAGS = $(USBLIBS) 
endif


# now construct normal env vars based on OS-specific ones
INCLUDES = -I. -I../c_host $(JAVAINCLUDE) $(JAVANATINC) 
OBJ = ../c_host/hiddata.o  ../c_host/linkm-lib.o  native$(TARGET).o 

CFLAGS  = $(OS_CFLAGS) -O -Wall -std=gnu99  $(INCLUDES)
LDFLAGS = $(OS_LDFLAGS) 

CC = gcc

# add linkmbootload fun
INCLUDES += -I../bootloadHID/commandline
LDFLAGS  += -L../bootloadHID/commandline -llinkmbootload


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
	@echo "make javadoc ... to make the javadoc"

javac:
	javac -target 1.5 thingm/linkm/$(TARGET).java	

jni:
	which javah
	javah -jni thingm.linkm.$(TARGET)

# the "libprep" is to pull out the libusb.a into its own dir, for static build
#libprep:
#	mkdir -p $(LIBUSBA_DIR)
#	cp `libusb-config --exec-prefix`/lib/libusb.a $(LIBUSBA_DIR)/$(LIBUSBA)

#	$(CC)  -o $(LIBTARGET) $(CFLAGS) $(LDFLAGS) $(OBJ)  -lc
compile: msg $(OBJ)
	$(CC)  -o $(LIBTARGET) $(CFLAGS) $(OBJ) $(LDFLAGS) 
	mkdir -p libtargets && mv $(LIBTARGET) libtargets

.c.o:
	$(CC) $(ARCH_COMPILE) $(CFLAGS) -c $*.c -o $*.o

msg: 
	@echo "building for OS=$(OS)"

# packaging
jar: javac jni compile
	jar -cfm linkm.jar  packaging/Manifest.txt thingm/linkm/*.class
	mv linkm.jar libtargets

processing: processinglib
processinglib:
	rm -f linkm.zip
	mkdir -p linkm/library
	cp packaging/processing-export.txt linkm/library/export.txt
	cp libtargets/* linkm/library
	zip -r linkm.zip linkm
	@echo
	@echo "now unzip linkm.zip into ~/Documents/Processing/libraries"
	@echo "or maybe just: cp -r linkm ~/Documents/Processing/libraries"

javadoc:
	cd doc && javadoc -sourcepath .. thingm.linkm && cd ..

clean:
	rm -f thingm/linkm/*.class *.o ../c_host/*.o 
	rm -f libtargets/linkm.jar
	rm -f libtargets/$(LIBTARGET)
	rm -f $(LIBTARGET) thingm_linkm_$(TARGET).h
	rm -f linkm.jar linkm.zip
	rm -rf linkm






###########################################################################

## NOTES ##

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