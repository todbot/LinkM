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

# this almost works for os x, but bleagh
#USBLIBS  = `libusb-legacy-config --libs | perl -nle '/L(.+?)\s+(.+)/; print "\x$1/libusb.a \$2"'`

TARGET=linkm-tool

# Mac OS X: "sudo port install libusb-legacy" using MacPorts
# Use the following 5 lines Mac OS X (and almost unix):
USBFLAGS =   `libusb-legacy-config --cflags`
#USBLIBS  =   `libusb-legacy-config --libs`
USBLIBS  =    /opt/local/lib/libusb-legacy/libusb.a
USBLIBS +=    -Wl,-framework -Wl,IOKit -Wl,-framework -Wl,CoreFoundation -Wl,-prebind
OS_CFLAGS= -arch i386 -arch x86_64 
OS_LIBS= $(OS_CFLAGS)
EXE_SUFFIX=

# Use the following 3 lines on Windows and comment out the 3 above:
#USBFLAGS=
#USBLIBS=    -lhid -lusb -lsetupapi
#OS_CFLAGS=
#OS_LIBS=
#EXE_SUFFIX= .exe

CC=				gcc
ARCHS=          
CFLAGS=			$(OS_CFLAGS) -O -Wall -std=gnu99  $(USBFLAGS) 
LIBS=			$(OS_LIBS) $(USBLIBS) 


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

# shows shared lib usage on Mac OS X
otool:
	otool -L $(TARGET)