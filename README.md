# LinkM -- USB to I2C adapter for BlinkM Smart LEDs

2010-2026 Tod E. Kurt, ThingM


![](https://raw.githubusercontent.com/todbot/LinkM/master/docs/linkm1.jpg)![](https://raw.githubusercontent.com/todbot/LinkM/master/docs/linkm2.jpg)
![](https://raw.githubusercontent.com/todbot/LinkM/master/docs/linkm3.jpg)![](https://raw.githubusercontent.com/todbot/LinkM/master/docs/linkm4.jpg)

LinkM datasheet: https://github.com/todbot/LinkM/raw/master/docs/LinkM_datasheet.pdf


Hosted on Github at https://github.com/todbot/LinkM/

## BlinkMSequencer

Create BlinkM light scripts using a drum machine-style metaphor and requires no
programming or hardware experience.

Modern BlinkMSequencer at https://github.com/todbot/BlinkMSequencer

Available for MacOS / Windows / Linux.


## linkm-tool

Commandline tool for controlling LinkM and BlinkMs.

Pre-compiled versions available in the [Releases section](https://github.com/todbot/LinkM/releases).


## Repo contents

This project contains the following directories:

- c_host          -- C library for talking to LinkM
  - linkm-tool       -- Command-line tool for exercising C library

- java_host       -- Java library for talking to LinkM
  - linkm.sh         -- Command-line tool for exercising Java library

- processing_apps -- Several applications using Java library and Processing
  - BlinkMSequencer2 -- Multi-channel light sequencer
  - BlinkMScriptTool -- Helps write text light scripts
  - TwitterBlinkM    -- Turns BlinkMs colors from twitter stream mentions
  - OSCLinkM         -- OSC gateway for LinkM
  - LinkMLibTest     -- Simple tests of LinkM Processing/Java library

- tools           -- Misc tools
  - linkm_load       -- mass bootloading tool
  - linux_usb_setup  -- fixes USB permissions on Ubuntu & other udev Linux

- schematic       -- LinkM device schematics in Eagle format

- firmware        -- LinkM device firmware code

- bootloadHID     -- LinkM device bootloader firmware and commandline tool
  - firmware         -- firmware for bootloader
  - commandline      -- commandline host-side tool to upload new firmware



## Building linkm-tool

The build process for linkm-tool is expected to be done entirely from the
command-line using standard free Unix-like tools such as "make" and "gcc".

On unix-like environments, the build process is just:

```sh
cd LinkM/c_host
make
```

Dependencies:
- The C library in "c_host" depends on library in "bootloadHID/commandline"
- `c_host/linkm-tool` requires **hidapi** (replaces the older libusb dependency)

On Mac OS X you will need the following free tools:
- XCode - http://developer.apple.com/technologies/xcode.html
- hidapi - `brew install hidapi`

On Windows (MinGW/MSYS2) you will need:
- MinGW/MSYS2 - https://www.msys2.org/
- The Windows build uses the native Win32 HID API; no extra library needed.

On Ubuntu / Debian Linux you will need:
- build-essential - `sudo apt-get install build-essential`
- hidapi - `sudo apt-get install libhidapi-dev`

On Fedora / RHEL Linux:
- `sudo dnf install hidapi-devel`

On Arch Linux:
- `sudo pacman -S hidapi`

On Linux, non-root users also need permission to access the device.
Add udev rules and reload:

```sh
cat << 'EOF' | sudo tee /etc/udev/rules.d/99-linkm.rules
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="20a0", ATTRS{idProduct}=="4110", MODE="0666"
SUBSYSTEM=="usb",    ATTR{idVendor}=="20a0",  ATTR{idProduct}=="4110",  MODE="0666"
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger
```


### Building the LinkM firmware

In general you should have everything you have for the host code above, and:

On Mac OS X:
- AVR CrossPack - http://www.obdev.at/products/crosspack/

On Windows:
- WinAVR - http://winavr.sourceforge.net/

On Ubuntu Linux:
- "sudo apt-get install avrdude avr-libc avr-gcc avr-binutils"




