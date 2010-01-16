# linkm-tool -- 
#  based off of obdev hid-data "hidtool"
#
#
# Name: Makefile
# Project: hid-data example
# Author: Christian Starkjohann
# Creation Date: 2008-04-11
# Tabsize: 4
# Copyright: (c) 2008 by OBJECTIVE DEVELOPMENT Software GmbH
# License: GNU GPL v2 (see License.txt), GNU GPL v3 or proprietary (CommercialLicense.txt)
# This Revision: $Id: Makefile 692 2008-11-07 15:07:40Z cs $

# Please read the definitions below and edit them as appropriate for your
# system:

TARGET=linkm-tool

# Use the following 3 lines on Unix and Mac OS X:
#USBFLAGS=   `libusb-config --cflags`
#USBLIBS=    `libusb-config --libs`

USBFLAGS=   `libusb-legacy-config --cflags`
USBLIBS=    /opt/local/lib/libusb-legacy/libusb.a -Wl,-framework -Wl,IOKit -Wl,-framework -Wl,CoreFoundation -Wl,-prebind
EXE_SUFFIX=

# Use the following 3 lines on Windows and comment out the 3 above:
#USBFLAGS=
#USBLIBS=    -lhid -lusb -lsetupapi
#EXE_SUFFIX= .exe

CC=				gcc
ARCHS=          -arch i386 -arch x86_64 
CFLAGS=			$(ARCHS) -O -Wall -std=gnu99  $(USBFLAGS) 
LIBS=			$(ARCHS) $(USBLIBS) 
#CFLAGS=		-arch i386 -arch ppc -O -Wall -std=gnu99  $(USBFLAGS) 
#LIBS=			-arch i386 -arch ppc $(USBLIBS)
#FIXME: figure out 'arch' better

OBJ=		$(TARGET).o linkm-lib.o hiddata.o 

PROGRAM=	$(TARGET)$(EXE_SUFFIX)

all: $(PROGRAM)

$(PROGRAM): $(OBJ)
	$(CC) -o $(PROGRAM) $(OBJ) $(LIBS) 

strip: $(PROGRAM)
	strip $(PROGRAM)

clean:
	rm -f $(OBJ) $(PROGRAM)

.c.o:
	$(CC) $(ARCH_COMPILE) $(CFLAGS) -c $*.c -o $*.o
