/**
 * LinkM_ProMicro -- LinkM USB HID to I2C bridge emulator
 *
 * Runs on Arduino Pro Micro (ATmega32U4, 16 MHz).
 * Presents as VID=0x20A0 / PID=0x4110 "ThingM" / "LinkM" to the host.
 * All USB communication uses HID Feature Reports (control transfers).
 *
 * BEFORE UPLOADING: set VID/PID, USB strings, and disable CDC.
 * CDC must be disabled so macOS allows libusb to access the HID interface.
 *
 *   arduino-cli compile \
 *     --fqbn SparkFun:avr:promicro:cpu=16MHzatmega32U4 \
 *     --build-property "build.extra_flags=-DUSB_VID=0x20A0 -DUSB_PID=0x4110 -DUSB_MANUFACTURER=\"ThingM\" -DUSB_PRODUCT=\"LinkM\" -DCDC_DISABLED" \
 *     --clean \
 *     .
 *
 * NOTE: with CDC disabled there is no USB serial port. To reset into the
 * bootloader for re-upload, briefly short RST to GND twice in quick succession
 * (the Pro Micro has no reset button — use a jumper wire). RX LED will pulse.
 *
 * HARDWARE CONNECTIONS:
 *   SDA → Pro Micro pin 2  (internal pull-ups enabled; add 4.7kΩ for long runs)
 *   SCL → Pro Micro pin 3  (internal pull-ups enabled; add 4.7kΩ for long runs)
 *   Status LED → RX LED (pin 17) on SparkFun Pro Micro
 *
 * TEST (after uploading with correct VID/PID):
 *   cd LinkM/c_host && make
 *   ./linkm-tool --linkmversion      # → version 0x13 0x36
 *   ./linkm-tool --i2cscan           # → lists I2C devices on bus
 *   ./linkm-tool -a 9 --color 255,0,0
 *
 * 2009/2025, Tod E. Kurt, ThingM, http://thingm.com/
 */

#include "LinkMHID.h"

// Global instance — constructor must run before USB enumeration begins.
// Arduino guarantees global constructors execute before setup().
LinkMHID LinkMDevice;

void setup() {
    LinkMDevice.begin();
}

void loop() {
    // Process any USB HID command received since last loop iteration
    LinkMDevice.processIfReady();

    // Drive the autonomous BlinkM script playback state machine
    LinkMDevice.playTicker();
}
