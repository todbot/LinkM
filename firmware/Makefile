#
# To package for production, do:
# - pushd ../bootloadHID/firmware && make clean && make && popd
# - make clean
# - make 
# - make combined  -- combines bootloadHID firmware with this one
# - make packaging
#
#
#
#
#
# BASED ON:
# Name: Makefile
# Project: hid-data example
# Author: Christian Starkjohann
# Creation Date: 2008-04-07
# Tabsize: 4
# Copyright: (c) 2008 by OBJECTIVE DEVELOPMENT Software GmbH
# License: GNU GPL v2 (see License.txt), GNU GPL v3 or proprietary (CommercialLicense.txt)
# This Revision: $Id: Makefile 692 2008-11-07 15:07:40Z cs $


TARGET = linkm

#MCU  = atmega88
MCU  = atmega88p
#MCU  = atmega168
F_CPU   = 12000000	# in Hz
#F_CPU   = 16000000	# in Hz

# for atmega88  (from arduino diecimila)
FUSE_L = 0xFF
FUSE_H = 0xDD
FUSE_E = 0x00    
FUSE_LOCK = 0x0F
FUSE_UNLOCK = 0x3F
# in avrstudio, reads as ff,dd,f8, cf (lockbit)

#for atmega88 (no!)
#FUSE_L=0xdf
#FUSE_H=0xde
#FUSE_E=0x00

# for atmega8
#FUSE_L=0xdf # see below for fuse values for particular devices
#FUSE_H=0xdd 

PKGTARGET = $(TARGET)v1
PKGDATE = `date +%Y%m%d`

#AVRDUDE = avrdude -c usbasp -p $(MCU) # edit this line for your programmer
AVRDUDE = avrdude -c avrispmkii -P usb -p $(MCU) -F
#AVRDUDE = avrdude -c stk600 -P usb -p $(MCU) 
# stk600 used for testing of programmed chips

CFLAGS  = -Iusbdrv -I. -I../c_host -DDEBUG_LEVEL=0
OBJECTS = twimaster.c uart.c
OBJECTS += usbdrv/usbdrv.o usbdrv/usbdrvasm.o usbdrv/oddebug.o 
OBJECTS += $(TARGET).o 

COMPILE = avr-gcc -std=gnu99 -Wall -Os -DF_CPU=$(F_CPU) $(CFLAGS) -mmcu=$(MCU)

##############################################################################
# Fuse values for particular devices
############################## ATMega48/88/168 ##############################
# ATMega*8 FUSE_L (Fuse low byte):
# 0xdf = 1 1 0 1   1 1 1 1
#        ^ ^ \ /   \--+--/
#        | |  |       +------- CKSEL 3..0 (external >8M crystal)
#        | |  +--------------- SUT 1..0 (crystal osc, BOD enabled)
#        | +------------------ CKOUT (if 0: Clock output enabled)
#        +-------------------- CKDIV8 (if 0: divide by 8)
# ATMega*8 FUSE_H (Fuse high byte):
# 0xde = 1 1 0 1   1 1 1 0
#        ^ ^ ^ ^   ^ \-+-/
#        | | | |   |   +------ BODLEVEL 0..2 (110 = 1.8 V)
#        | | | |   + --------- EESAVE (preserve EEPROM over chip erase)
#        | | | +-------------- WDTON (if 0: watchdog always on)
#        | | +---------------- SPIEN (allow serial programming)
#        | +------------------ DWEN (debug wire enable)
#        +-------------------- RSTDISBL (reset pin is enabled)
#

all: hex eep

# symbolic targets:
help:
	@echo "This Makefile has no default rule. Use one of the following:"
	@echo "make hex ....... to build $(TARGET).hex"
	@echo "make program ... to flash the firmware"
	@echo "make fuse ...... to flash the fuses"
	@echo "make readfuse .. to read fuses to _fuse.txt files"
	@echo "make flash ..... to flash the firmware" 
	@echo "make clean ..... to delete objects and hex file"

packaging:
	echo "making $(PKGTARGET)_$(PKGDATE)"
	mkdir -p $(PKGTARGET)_$(PKGDATE)
	cp -f $(TARGET).hex $(PKGTARGET)_$(PKGDATE)/$(PKGTARGET)_$(PKGDATE).hex
	cp -f $(TARGET).eep $(PKGTARGET)_$(PKGDATE)/$(PKGTARGET)_$(PKGDATE).eep
	cp -f $(PKGTARGET)_$(MCU)_fuses.txt $(PKGTARGET)_$(PKGDATE)
	zip -r $(PKGTARGET)_$(PKGDATE).zip $(PKGTARGET)_$(PKGDATE)
# build: elf hex eep lss sym


hex: $(TARGET).hex
eep: $(TARGET).eep

combined: hex
	cp $(TARGET).hex $(TARGET)_withoutbootload.hex
	srec_cat $(TARGET).hex -Intel ../bootloadHID/firmware/main.hex -Intel -o $(TARGET)_withbootload.hex -Intel

program: flash

erase:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -e -U lfuse:w:$(FUSE_L):m -U hfuse:w:$(FUSE_H):m -U efuse:w:$(FUSE_E):m

# rule for programming fuse bits:
fuse:
	@[ "$(FUSE_H)" != "" -a "$(FUSE_L)" != "" ] || \
		{ echo "*** Edit Makefile and choose values for FUSE_L and FUSE_H!"; exit 1; }
	$(AVRDUDE) -U hfuse:w:$(FUSE_H):m -U lfuse:w:$(FUSE_L):m -U efuse:w:$(FUSE_E):m
lock:
	$(AVRDUDE) -U lock:w:$(FUSE_LOCK):m
unlock:
	$(AVRDUDE) -U lock:w:$(FUSE_UNLOCK):m

readfuse: getfuse
getfuse:
	rm -f hfuse.txt lfuse.txt efuse.txt lockfuse.txt
	$(AVRDUDE) -U hfuse:r:hfuse.txt:h -U lfuse:r:lfuse.txt:h -U efuse:r:efuse.txt:h -U lock:r:lockfuse.txt:h

readflash:
	$(AVRDUDE) -U flash:r:readflash.hex:i

# rule for uploading firmware:
flash: $(TARGET).hex
	$(AVRDUDE) -U flash:w:$(TARGET).hex:i -U eeprom:w:$(TARGET).eep:i

flashcombined: combined
	$(AVRDUDE) -U flash:w:$(TARGET)_withbootload.hex:i -U eeprom:w:$(TARGET).eep:i

# rule for deleting dependent files (those which can be built by Make):
clean:
	rm -f $(TARGET).hex $(TARGET).eep $(TARGET).lst $(TARGET).obj $(TARGET).cof $(TARGET).list $(TARGET).map $(TARGET).eep.hex $(TARGET).elf *.o usbdrv/*.o $(TARGET).s usbdrv/oddebug.s usbdrv/usbdrv.s

# Generic rule for compiling C files:
.c.o:
	$(COMPILE) -c $< -o $@

# Generic rule for assembling Assembler source files:
.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.

# Generic rule for compiling C to assembler, used for debugging only.
.c.s:
	$(COMPILE) -S $< -o $@

# file targets:

# Since we don't want to ship the driver multipe times, we copy it into this project:
usbdrv:
	cp -r ../../../usbdrv .

$(TARGET).elf: usbdrv $(OBJECTS)	# usbdrv dependency only needed because we copy it
	$(COMPILE) -o $(TARGET).elf $(OBJECTS)

$(TARGET).hex: $(TARGET).elf
	rm -f $(TARGET).hex $(TARGET).eep.hex
	avr-objcopy -j .text -j .data -O ihex $(TARGET).elf $(TARGET).hex
	avr-objcopy -O ihex -R .eeprom $< $@
	avr-size --mcu=$(MCU) --format=avr $(TARGET).elf
	@echo "True available space = 8k-2k = 6144 bytes"

%.lss: %.elf
	avr-objdump -h -S $< > $@

%.eep: %.elf
	@echo
#	@echo $(MSG_EEPROM) $@
	avr-objcopy -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 -O ihex $< $@

# debugging targets:

disasm:	$(TARGET).elf
	avr-objdump -d $(TARGET).elf

cpp:
	$(COMPILE) -E $(TARGET).c
