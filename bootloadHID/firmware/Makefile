# Name: Makefile
# Project: bootloadHID
# Author: Christian Starkjohann
# Creation Date: 2007-03-19
# Tabsize: 4
# Copyright: (c) 2007 by OBJECTIVE DEVELOPMENT Software GmbH
# License: GNU GPL v2 (see License.txt)
# This Revision: $Id: Makefile 684 2008-10-22 18:43:39Z cs $

###############################################################################
# Configure the following variables according to your AVR. The example below
# is for an ATMega8. Program the device with
#     make fuse    # to set the clock generator, boot section size etc.
#     make flash   # to load the boot loader into flash
#     make lock    # to protect the boot loader from overwriting

#DEVICE = atmega8
#DEVICE = atmega88
DEVICE = atmega88p
BOOTLOADER_ADDRESS = 1800
F_CPU = 12000000
#F_CPU = 16000000

# from arduino 
#diecimila.bootloader.low_fuses=0xff
#diecimila.bootloader.high_fuses=0xdd
#diecimila.bootloader.extended_fuses=0x00
#diecimila.bootloader.path=atmega
#diecimila.bootloader.file=ATmegaBOOT_168_diecimila.hex
#diecimila.bootloader.unlock_bits=0x3F
#diecimila.bootloader.lock_bits=0x0F

# for atmega88  (from arduino diecimila)
FUSE_L = 0xFF
FUSE_H = 0xDD
FUSE_E = 0x00
FUSE_LOCK = 0x0F
FUSE_UNLOCK = 0x3F

# for atmega8
#FUSE_L = 0xdf
#FUSE_H = 0xc0
##FUSEL = 0x9f

# Fuse low byte:
# 0x9f = 1 0 0 1   1 1 1 1
#        ^ ^ \ /   \--+--/
#        | |  |       +------- CKSEL 3..0 (external >8M crystal)
#        | |  +--------------- SUT 1..0 (crystal osc, BOD enabled)
#        | +------------------ BODEN (BrownOut Detector enabled)
#        +-------------------- BODLEVEL (2.7V)
# Fuse high byte:
# 0xc0 = 1 1 0 0   0 0 0 0 <-- BOOTRST (boot reset vector at 0x1800)
#        ^ ^ ^ ^   ^ ^ ^------ BOOTSZ0
#        | | | |   | +-------- BOOTSZ1
#        | | | |   + --------- EESAVE (preserve EEPROM over chip erase)
#        | | | +-------------- CKOPT (full output swing)
#        | | +---------------- SPIEN (allow serial programming)
#        | +------------------ WDTON (WDT not always on)
#        +-------------------- RSTDISBL (reset pin is enabled)

###############################################################################

#AVRDUDE = avrdude -c stk500v2 -P avrdoper -p $(DEVICE)
AVRDUDE = avrdude -c avrispmkii -P usb -p $(DEVICE) -F

LDFLAGS += -Wl,--section-start=.text=$(BOOTLOADER_ADDRESS)

COMPILE = avr-gcc -Wall -Os -Iusbdrv -I. -mmcu=$(DEVICE) -DF_CPU=$(F_CPU) -DDEBUG_LEVEL=0 # -DTEST_MODE
# NEVER compile the final product with debugging! Any debug output will
# distort timing so that the specs can't be met.

OBJECTS =  usbdrv/usbdrvasm.o usbdrv/oddebug.o main.o


# symbolic targets:
all:	main.hex

.c.o:
	$(COMPILE) -c $< -o $@

.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.

.c.s:
	$(COMPILE) -S $< -o $@

program: flash
flash:	all
	$(AVRDUDE) -U flash:w:main.hex:i

readflash:
	$(AVRDUDE) -U flash:r:read.hex:i

fuse:
	$(AVRDUDE) -U hfuse:w:$(FUSE_H):m -U lfuse:w:$(FUSE_L):m -U efuse:w:$(FUSE_E):m

lock:
	$(AVRDUDE) -U lock:w:$(FUSE_LOCK):m
unlock:
	$(AVRDUDE) -U lock:w:$(FUSE_UNLOCK):m

readfuse: getfuse
getfuse:
	$(AVRDUDE) -U hfuse:r:hfuse.txt:h -U lfuse:r:lfuse.txt:h -U efuse:r:efuse.txt:h 

clean:
	rm -f main.hex main.bin *.o usbdrv/*.o main.s usbdrv/oddebug.s usbdrv/usbdrv.s

# file targets:
main.bin:	$(OBJECTS)
	$(COMPILE) -o main.bin $(OBJECTS) $(LDFLAGS)

main.hex:	main.bin
	rm -f main.hex main.eep.hex
	avr-objcopy -j .text -j .data -O ihex main.bin main.hex
	avr-size main.bin

disasm:	main.bin
	avr-objdump -d main.bin

cpp:
	$(COMPILE) -E main.c
