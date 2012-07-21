# Makefile for "linkmbootload" and "linkmboot-lib"
#
#
#
# Platform-specific notes:
#
# Mac OS X 
#   - Install Xcode with Unix Dev Support 
#   - Install 'make' from macports (or similar)
# Windows XP/7  
#   - Install MinGW and MSYS (http://www.tdragon.net/recentgcc/ )
# Linux (Ubuntu) 
#   - apt-get install gcc-avr avr-libc avrdude java librxtx-java
#
#
#
#

PROGNAME = linkmbootload

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
# Mac OS X: "sudo port install libusb-legacy +universal" using MacPorts
# If you want to build for PowerPC too, you'll need to edit 
# /opt/local/etc/macports/macports.conf: universal_archs and add "ppc"
# otherwise swap the OS_CFLAGS with the commented one below
#USBFLAGS =  `libusb-legacy-config --cflags`
#USBLIBS  =  /opt/local/lib/libusb-legacy/libusb.a
#USBFLAGS = `libusb-config --cflags`
#USBLIBS = `libusb-config --libs | cut -d' ' -f1 | cut -c3- `/libusb.a

USBFLAGS = `/opt/local/bin/libusb-legacy-config --cflags`
# get just the path to the static lib
USBLIBS = `/opt/local/bin/libusb-legacy-config --libs | cut -d' ' -f1 | cut -c3- `/libusb-legacy.a
# get everything else in --libs
USBLIBS +=  `libusb-legacy-config --libs | cut -d' ' -f 3- `

#OS_CFLAGS= -arch i386 
#OS_CFLAGS= -arch i386 -arch ppc
#OS_CFLAGS= -arch i386 -arch x86_64 -arch ppc
OS_CFLAGS= -arch i386 -arch x86_64
#OS_CFLAGS += -isysroot /Developer/SDKs/MacOSX10.5.sdk -mmacosx-version-min=10.5 -no_compact_linkedit
#OS_CFLAGS += -no_compact_linkedit
OS_LIBS  = $(OS_CFLAGS) 
EXE_SUFFIX=
endif

#################  Windows  ##################################################
ifeq "$(OS)" "windows"
USBFLAGS=
USBLIBS=    -lhid -lsetupapi
EXE_SUFFIX= .exe
endif

#################  Linux  ###################################################
ifeq "$(OS)" "linux"
USBFLAGS =   `libusb-config --cflags`
USBLIBS  =   `libusb-config --libs`
EXE_SUFFIX=
endif


CC=		gcc
CFLAGS=	$(OS_CFLAGS) -O -Wall -std=gnu99 $(USBFLAGS) -DPROGNAME=\"$(PROGNAME)\"
LIBS=	$(OS_LIBS) $(USBLIBS)


OBJ=		$(PROGNAME).o $(PROGNAME)-lib.o usbcalls.o
PROGRAM=	$(PROGNAME)$(EXE_SUFFIX)


all: msg $(PROGRAM) 

msg: 
	@echo "Building for OS=$(OS)"

$(PROGRAM): lib
	$(CC) $(CFLAGS) $(LIBS) -L. -l$(PROGNAME) -o $(PROGRAM) $(LIBS)

# FIXME: this isn't cross-platform I think
lib: $(OBJ)
	rm -f lib$(PROGNAME).a   # FIXME
	ar rcs lib$(PROGNAME).a $(OBJ) 


msleeptst: 
	$(CC) $(CFLAGS) -o msleeptst$(EXE_SUFFIX) msleeptst.c  $(LIBS)

strip: $(PROGRAM)
	strip $(PROGRAM)

clean:
	rm -f $(OBJ) $(PROGRAM) lib$(PROGNAME).a msleeptst.o 

.c.o:
	$(CC) $(ARCH_COMPILE) $(CFLAGS) -c $*.c -o $*.o
