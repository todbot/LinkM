
README for "linkm" project
==========================
2010 Tod E. Kurt, ThingM

OVERVIEW
--------
This project contains the following directories:

- c_host          -- C library for talking to LinkM
  - linkm-tool       -- Command-line tool for testing C library
- java_host       -- Java library for talking to LinkM 
  - linkm.sh         -- Command-line tool for testing Java library
- processing_apps -- Several applications using Java library and Processing
  - BlinkMSequencer2 -- Multi-channel light sequencer
  - BlinkMScriptTool -- Helps write text light scripts
  - TwitterBlinkM    -- Turns BlinkMs colors from twitter stream mentions
  - OSCLinkM         -- OSC gateway for LinkM
  - LinkMLibTest     -- Simple tests of LinkM Processing/Java library
- tools           -- Misc tools
  - linkm_load       -- mass bootloading tool
  - linux_usb_setup  -- fixes USB permissions on Ubuntu & other udev Linux 
- schematic       -- LinkM device schematics
- firmware        -- LinkM device firmware code
- bootloadHID     -- LinkM device bootloader firmware and commandline tool 



BUILDING THE PC-SIDE (HOST) CODE
--------------------------------
There is a "build_all.sh" script that should build all the host code

Host code dependencies:
- The Java library in "java_host" depends on the C library in "c_host"
- The C library in "c_host" depends on library in "bootloadHID/commandline"

On Mac OS X you will need the following free tools:
- XCode - http://developer.apple.com/technologies/xcode.html
- libusb - "sudo port install libusb-legacy libusb"

On Windows you will need the following free tools:
- MinGW - 
- MSYS -
- zip - http://stahlworks.com/dev/index.php?tool=zipunzip
- Java JDK - http://java.sun.com/javase/downloads/widget/jdk6.jsp

On Ubuntu Linux you will need the following free tools:
- libusb - "sudo apt-get install libusb libusb-dev"
- 
- 

BUILDING THE FIRMWARE
---------------------
In general you should have everything you have for the host code above, and:

On Mac OS X:
- AVR CrossPack - http://www.obdev.at/products/crosspack/
 
On Windows:
- WinAVR - http://winavr.sourceforge.net/

On Ubuntu Linux:
- "sudo apt-get install avrdude avr-libc avr-gcc avr-binutils"

 