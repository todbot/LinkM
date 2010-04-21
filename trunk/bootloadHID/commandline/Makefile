# Makefile for "linkmbootload" and "linkmboot-lib"
# should work on Mac OS X, Windows, and Linux
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

# if all else fails, assume mac :)
ifndef "$(OS)" 
	OS=macosx
endif

#################  Mac OS X  ##################################################
ifeq "$(OS)" "macosx"
# Mac OS X: "sudo port install libusb-legacy" using MacPorts
# Use the following 5 lines Mac OS X (and almost unix):
USBFLAGS =   `libusb-legacy-config --cflags`
#USBLIBS  =   `libusb-legacy-config --libs`
USBLIBS  =    /opt/local/lib/libusb-legacy/libusb.a
USBLIBS +=    -Wl,-framework -Wl,IOKit -Wl,-framework -Wl,CoreFoundation -Wl,-prebind
OS_CFLAGS= -arch i386 -arch x86_64 
OS_LIBS= $(OS_CFLAGS) 
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
CXX=	g++
#CFLAGS=	$(OS_CFLAGS) -std=gnu99 -O2 -Wall $(USBFLAGS) -DPROGNAME=\"$(PROGNAME)\"
CFLAGS=	$(OS_CFLAGS) -O -Wall -std=gnu99 $(USBFLAGS) -DPROGNAME=\"$(PROGNAME)\"
LIBS=	$(OS_LIBS) $(USBLIBS)


OBJ=		$(PROGNAME).o $(PROGNAME)-lib.o usbcalls.o
PROGRAM=	$(PROGNAME)$(EXE_SUFFIX)


all: msg $(PROGRAM) 

msg: 
	@echo "building for OS=$(OS)"

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
