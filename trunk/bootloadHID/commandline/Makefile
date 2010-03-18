# Name: Makefile
# Project: Automator
# Author: Christian Starkjohann
# Creation Date: 2006-02-01
# Tabsize: 4
# Copyright: (c) 2006 by OBJECTIVE DEVELOPMENT Software GmbH
# License: Proprietary, free under certain conditions. See Documentation.
# This Revision: $Id: Makefile 281 2007-03-20 13:22:10Z cs $

# Please read the definitions below and edit them as appropriate for your
# system:

PROGNAME = linkmbootload

# assume macosx for ease of my develoment
ifndef OS
	OS=macosx
endif

ifeq "$(OS)" "Windows_NT"
	OS=windows
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
CFLAGS=	$(OS_CFLAGS) -std=gnu99 -O2 -Wall $(USBFLAGS) -DPROGNAME=\"$(PROGNAME)\"
LIBS=	$(OS_LIBS) $(USBLIBS)

	
OBJ=		$(PROGRAM).o usbcalls.o
PROGRAM=	$(PROGNAME)$(EXE_SUFFIX)

all: $(PROGRAM)

$(PROGRAM): $(OBJ)
	$(CC) $(CFLAGS) -o $(PROGRAM) $(OBJ) $(LIBS)

msleeptst: 
	$(CC) $(CFLAGS) -o msleeptst$(EXE_SUFFIX) msleeptst.c  $(LIBS)

strip: $(PROGRAM)
	strip $(PROGRAM)

clean:
	rm -f $(OBJ) $(PROGRAM) msleeptst.o

.c.o:
	$(CC) $(ARCH_COMPILE) $(CFLAGS) -c $*.c -o $*.o
