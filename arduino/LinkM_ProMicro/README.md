# LinkM Emulator for Arduino Pro Micro (ATmega32U4)

Firmware that turns a SparkFun Pro Micro (ATmega32U4) into a drop-in replacement
for a ThingM LinkM USB HID to I2C adapter.  The emulator is wire-compatible with
the existing `linkm-tool` CLI and all LinkM host libraries — no host-side changes
required.

---

## What this does

The original LinkM is an ATmega88P device using V-USB (software USB) to present a
USB HID interface to the host.  The host sends commands via **HID feature reports**
(SET_REPORT / GET_REPORT control transfers, Report ID 1, 8 bytes) which the firmware
translates into I2C transactions.

This sketch ports that firmware to the ATmega32U4's native USB hardware, using
Arduino's `PluggableUSB` API to implement the same HID descriptor and feature-report
protocol.  From the host's perspective the device is identical:

| Property       | Value              |
|----------------|--------------------|
| USB Vendor ID  | `0x20A0`           |
| USB Product ID | `0x4110`           |
| Manufacturer   | `ThingM`           |
| Product        | `LinkM`            |
| HID interface  | Vendor feature report, Report ID 1, 8 bytes |

---

## File overview

| File                  | Purpose                                                  |
|-----------------------|----------------------------------------------------------|
| `LinkM_ProMicro.ino`  | `setup()` / `loop()` — 10 lines                          |
| `LinkMHID.h`          | `PluggableUSBModule` subclass declaration                 |
| `LinkMHID.cpp`        | USB descriptors, feature-report handling, all 13 commands, I2C via Wire, EEPROM, play-ticker |
| `linkm_protocol.h`    | Command/error constants (mirrors `c_host/linkm-lib.h`)   |

---

## Hardware

**Board:** SparkFun Pro Micro — **5V / 16 MHz** variant (ATmega32U4)

> **Important:** The SparkFun Pro Micro board package defaults to the
> **3.3 V / 8 MHz** processor option.  You must select **ATmega32U4 (5V, 16 MHz)**
> before compiling.  At 8 MHz the USB timing is out of spec for full-speed USB
> and the device will fail to enumerate reliably.
>
> In the Arduino IDE: **Tools → Processor → ATmega32U4 (5V, 16 MHz)**
>
> With arduino-cli the FQBN option `:cpu=16MHzatmega32U4` (shown in all compile
> commands below) selects this mode.

**I2C wiring:**

| Pro Micro pin | Signal | Notes                            |
|---------------|--------|----------------------------------|
| 2 (SDA)       | SDA    | 4.7 kΩ pull-up to VCC           |
| 3 (SCL)       | SCL    | 4.7 kΩ pull-up to VCC           |
| GND           | GND    | Common ground with I2C devices   |

The I2C bus runs at 100 kHz.  Pro Micro is the bus master; all BlinkMs and other
I2C peripherals are slaves.

---

## Prerequisites

### 1. arduino-cli

```sh
brew install arduino-cli      # macOS
# or download from https://arduino.cc/en/software#arduino-cli
```

Verify:

```sh
arduino-cli version
```

### 2. SparkFun AVR board package

```sh
arduino-cli config init
arduino-cli config add board_manager.additional_urls \
    https://raw.githubusercontent.com/sparkfun/Arduino_Boards/master/IDE_Board_Manager/package_sparkfun_index.json
arduino-cli core update-index
arduino-cli core install SparkFun:avr
```

Verify the Pro Micro board is visible:

```sh
arduino-cli board listall | grep promicro
# SparkFun Pro Micro    SparkFun:avr:promicro
```

### 3. No extra libraries required

All libraries used (`Wire`, `EEPROM`, `PluggableUSB`) are part of the Arduino AVR
core and ship with `SparkFun:avr`.

---

## Compile

The Pro Micro defaults to SparkFun's VID/PID (`0x1B4F / 0x9206`).  Pass the
LinkM identity and CDC-disable flags on the command line:

> **Why `-DCDC_DISABLED`?**  On macOS the `AppleUSBCDC` kernel driver claims the
> CDC interface and prevents libusb from sending control transfers to the device.
> Disabling CDC removes that interface entirely, allowing libusb to access the
> HID interface directly.  With CDC disabled there is no USB serial port; use
> the RST-to-GND method described in the Upload section to re-flash.
>
> Note: the flag is `-DCDC_DISABLED` (define a symbol), not `-UCDC_ENABLED`
> (undefine a symbol) — the Arduino core uses `#ifndef CDC_DISABLED` in
> `USBDesc.h`, so `-U` has no effect on a header-file `#define`.

```sh
cd LinkM/arduino/LinkM_ProMicro

arduino-cli compile \
    --fqbn SparkFun:avr:promicro:cpu=16MHzatmega32U4 \
    --build-property "build.extra_flags=-DUSB_VID=0x20A0 -DUSB_PID=0x4110 -DUSB_MANUFACTURER=\"ThingM\" -DUSB_PRODUCT=\"LinkM\" -DCDC_DISABLED" \
    .
```

### Alternative: platform.local.txt

To avoid repeating the flags on every compile, create a `platform.local.txt`
file that injects them automatically:

```sh
PLATFORM_DIR=$(arduino-cli config dump --format json | \
    python3 -c "import sys,json; d=json.load(sys.stdin); \
    print(d['directories']['data'])")/packages/SparkFun/hardware/avr/1.1.13

cat > "$PLATFORM_DIR/platform.local.txt" << 'EOF'
build.extra_flags=-DUSB_VID=0x20A0 -DUSB_PID=0x4110 -DUSB_MANUFACTURER="ThingM" -DUSB_PRODUCT="LinkM" -DCDC_DISABLED
EOF
```

With that file in place the shorter form works:

```sh
arduino-cli compile \
    --fqbn SparkFun:avr:promicro:cpu=16MHzatmega32U4 \
    .
```

> `platform.local.txt` is loaded after `platform.txt` and survives IDE/CLI
> restarts, but must be recreated if the SparkFun package is updated to a new
> version directory.

---

## Upload

Because CDC is disabled, the board does **not** appear as a serial port while
running.  To upload, you must force it into the Caterina bootloader manually:

1. **Briefly connect RST to GND twice in quick succession** (the Pro Micro has
   no reset button — use a jumper wire or tweezers on the RST and GND pins).
   The RX LED will begin pulsing, indicating the bootloader is active.
2. Within 8 seconds, find the bootloader port and upload:

```sh
arduino-cli board list
# Port                    Protocol  Type              Board Name
# /dev/cu.usbmodem14101   serial    Serial Port (USB) SparkFun Pro Micro

arduino-cli upload \
    --fqbn SparkFun:avr:promicro:cpu=16MHzatmega32U4 \
    --port /dev/cu.usbmodem14101 \
    .
```

> The bootloader port is a different path from any previous port.  Run
> `arduino-cli board list` immediately after the double-tap to see it.
>
> If the upload still fails, try again — the timing window is ~8 seconds.

After a successful upload the board re-enumerates as a HID-only device (no
serial port) with VID=0x20A0 / PID=0x4110.

---

## Verify enumeration

**macOS:**

```sh
system_profiler SPUSBDataType | grep -A 8 "LinkM"
```

Expected output:

```
LinkM:
  Product ID: 0x4110
  Vendor ID: 0x20a0
  Manufacturer: ThingM
  ...
```

**Linux:**

```sh
lsusb -d 20a0:4110
# Bus 001 Device 012: ID 20a0:4110 ThingM LinkM
```

---

## Test with linkm-tool

Build the host tool from this repository:

```sh
cd LinkM/c_host
make
```

Run tests (no I2C hardware needed for the first two):

```sh
# Firmware version — exercises a full SET_REPORT + GET_REPORT round-trip
./linkm-tool --linkmversion
# Expected: LinkM version 0x13 0x36

# Status LED toggle
./linkm-tool --statled 1
./linkm-tool --statled 0

# I2C scan (requires devices on SDA/SCL with pull-ups)
./linkm-tool --i2cscan

# BlinkM at address 9: stop, set colour to red, play script 0
./linkm-tool -a 9 --stop
./linkm-tool -a 9 --color 255,0,0
./linkm-tool -a 9 --play 0

# EEPROM round-trip
./linkm-tool --linkmeesave
./linkm-tool --linkmeeload
./linkm-tool --linkmversion   # confirm still responsive
```

---

## Implementation notes

### Commands supported

All 13 original LinkM commands are implemented:

| Cmd | Value | Notes |
|-----|-------|-------|
| I2CTRANS   | 1   | Write + optional repeated-START read |
| I2CWRITE   | 2   | Write, optionally hold bus open |
| I2CREAD    | 3   | Read only |
| I2CSCAN    | 4   | Probe each address; returns list of ACK'd devices |
| I2CCONN    | 5   | No-op (no bus-isolation chip on Pro Micro) |
| I2CINIT    | 6   | `Wire.end()` / `Wire.begin()` / `setClock(100000)` |
| VERSIONGET | 100 | Returns `0x13` / `0x36` (matches original firmware) |
| STATLEDSET | 101 | `LED_BUILTIN` (pin 17 on SparkFun Pro Micro) |
| STATLEDGET | 102 | |
| PLAYSET    | 103 | Sets autonomous BlinkM play-ticker params |
| PLAYGET    | 104 | |
| EESAVE     | 105 | `EEPROM.put()` at address 0 |
| EELOAD     | 106 | `EEPROM.get()` at address 0 |
| GOBOOTLOAD | 107 | Writes Caterina magic key `0x7777` → watchdog reset |

### PLAYSET buffer limit

The 8-byte feature report can carry at most 4 param bytes for PLAYSET (indices
4–7 of `rxBuf`): `playing`, `script_id`, `script_tick`, `script_len`.  The
original firmware had the same effective limit.  `start_pos`, `fadespeed`, and
`dir` are preserved from the last EELOAD or retain their defaults.

### Play-ticker timing

The original firmware fired at `12 MHz / 65536 / 6 ≈ 30.5 Hz` giving ~32.8 ms
per tick.  The emulator uses `millis()` with 33 ms per tick unit to match this
rate.

### I2C repeated START

`Wire.endTransmission(false)` (sendStop=false) is used when a read follows a
write in the same I2CTRANS command, issuing a repeated START rather than a
STOP+START.  This is required by BlinkM and many other I2C peripherals.

### Linux udev rule

On Linux, add a udev rule so non-root users can access the device:

```sh
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="20a0", ATTR{idProduct}=="4110", MODE="0666"' \
    | sudo tee /etc/udev/rules.d/99-linkm.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
```
