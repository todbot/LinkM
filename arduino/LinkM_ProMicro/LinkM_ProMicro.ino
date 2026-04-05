/**
 * LinkM_ProMicro -- LinkM USB HID to I2C bridge emulator
 *
 * Runs on Arduino Pro Micro (ATmega32U4, 16 MHz).
 * Presents as VID=0x20A0 / PID=0x4110 "ThingM" / "LinkM" to the host.
 * All USB communication uses HID Feature Reports (control transfers).
 *
 * BEFORE UPLOADING: set VID/PID and USB strings.
 *
 *   Option A — platform.local.txt (recommended):
 *     Create the file:
 *       ~/.arduino15/packages/SparkFun/hardware/avr/<version>/platform.local.txt
 *     Contents:
 *       build.extra_flags=-DUSB_VID=0x20A0 -DUSB_PID=0x4110 -DUSB_MANUFACTURER="ThingM" -DUSB_PRODUCT="LinkM"
 *
 *   Option B — Arduino CLI:
 *     arduino-cli compile \
 *       --build-property "build.extra_flags=-DUSB_VID=0x20A0 -DUSB_PID=0x4110 -DUSB_MANUFACTURER=\"ThingM\" -DUSB_PRODUCT=\"LinkM\""
 *       --fqbn SparkFun:avr:promicro LinkM_ProMicro
 *
 * HARDWARE CONNECTIONS:
 *   SDA → Pro Micro pin 2  (with 4.7kΩ pull-up to VCC)
 *   SCL → Pro Micro pin 3  (with 4.7kΩ pull-up to VCC)
 *   Status LED → LED_BUILTIN (pin 17 on SparkFun Pro Micro)
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
