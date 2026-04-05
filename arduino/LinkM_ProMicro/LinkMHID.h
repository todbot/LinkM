/**
 * LinkMHID.h -- Arduino Pro Micro (ATmega32U4) LinkM emulator
 *
 * Implements a PluggableUSBModule that presents the same USB HID
 * identity and feature-report protocol as a real LinkM device.
 *
 * USB identity: VID=0x20A0 PID=0x4110 "ThingM" / "LinkM"
 * (set via platform.local.txt — see README in this directory)
 */

#pragma once

#include <Arduino.h>
#include <PluggableUSB.h>
#include <Wire.h>
#include <avr/wdt.h>
#include "linkm_protocol.h"

// EEPROM address for params_t (7 bytes)
#define EE_PARAMS_ADDR  0

// playTicker timing: original ran at 12MHz/65536/6 ≈ 30.5 Hz → ~32.8 ms/tick
#define TICK_MS         33UL

// HID descriptor type constants (not all defined in Arduino HID.h)
#define HID_GET_REPORT              0x01
#define HID_SET_IDLE                0x0A
#define HID_SET_REPORT              0x09
#define HID_REPORT_TYPE_FEATURE     0x03
#define HID_DESCRIPTOR_TYPE         0x21
#define HID_REPORT_DESCRIPTOR_TYPE  0x22

// bmRequestType values for HID class requests.
// hiddata.c (the LinkM host library) uses LIBUSB_RECIPIENT_DEVICE (0x00),
// not LIBUSB_RECIPIENT_INTERFACE (0x01), so the values are 0x20/0xA0.
#define REQ_HOST_TO_DEVICE_CLASS    0x20  // Class | Device | H→D
#define REQ_DEVICE_TO_HOST_CLASS    0xA0  // Class | Device | D→H
// Accept interface-level requests too (correct per HID spec, sent by some hosts)
#define REQ_HOST_TO_DEVICE_CLASS_IF 0x21  // Class | Interface | H→D
#define REQ_DEVICE_TO_HOST_CLASS_IF 0xA1  // Class | Interface | D→H

// Playback state machine parameters (7 bytes, EEPROM-backed)
typedef struct {
    uint8_t playing;     // 0=stopped, 1=playing
    uint8_t script_id;   // BlinkM script number to play
    uint8_t script_tick; // timer ticks between script steps
    uint8_t script_len;  // total steps in the script
    uint8_t start_pos;   // starting position in script
    uint8_t fadespeed;   // BlinkM fade speed
    uint8_t dir;         // playback direction (future use)
} params_t;

// Combined interface + HID class + endpoint descriptor block
// written into the USB configuration descriptor by getInterface()
typedef struct {
    // Interface descriptor (9 bytes)
    uint8_t  bLength_if;
    uint8_t  bDescriptorType_if;
    uint8_t  bInterfaceNumber;
    uint8_t  bAlternateSetting;
    uint8_t  bNumEndpoints;
    uint8_t  bInterfaceClass;
    uint8_t  bInterfaceSubClass;
    uint8_t  bInterfaceProtocol;
    uint8_t  iInterface;
    // HID class descriptor (9 bytes, type 0x21)
    uint8_t  bLength_hid;
    uint8_t  bDescriptorType_hid;
    uint8_t  bcdHID_lo;
    uint8_t  bcdHID_hi;
    uint8_t  bCountryCode;
    uint8_t  bNumDescriptors;
    uint8_t  bDescriptorType_report;
    uint8_t  wDescriptorLength_lo;
    uint8_t  wDescriptorLength_hi;
    // Endpoint descriptor (7 bytes)
    uint8_t  bLength_ep;
    uint8_t  bDescriptorType_ep;
    uint8_t  bEndpointAddress;
    uint8_t  bmAttributes;
    uint8_t  wMaxPacketSize_lo;
    uint8_t  wMaxPacketSize_hi;
    uint8_t  bInterval;
} __attribute__((packed)) LinkMIfaceDescriptor;


class LinkMHID : public PluggableUSBModule {
public:
    LinkMHID();

    // Call from Arduino setup()
    void begin();

    // Call from Arduino loop() — processes any pending USB command
    void processIfReady();

    // Call from Arduino loop() — drives autonomous BlinkM script playback
    void playTicker();

protected:
    // ---- PluggableUSBModule interface ----
    int     getInterface(uint8_t* interfaceCount) override;
    int     getDescriptor(USBSetup& setup) override;
    bool    setup(USBSetup& setup) override;
    uint8_t getShortName(char* name) override;

private:
    uint8_t  epType[1];          // endpoint type array (one interrupt-in EP)

    uint8_t  rxBuf[REPORT1_COUNT]; // command received from host (SET_REPORT)
    uint8_t  txBuf[REPORT1_COUNT]; // response sent to host (GET_REPORT)
    volatile bool msgReady;        // set in USB ISR, consumed in loop()


    params_t params;
    uint16_t script_pos;
    uint32_t lastTickMs;

    // ---- Command handlers ----
    void handleMessage();
    void doI2CTrans();
    void doI2CWrite();
    void doI2CRead();
    void doI2CScan();

    // ---- BlinkM helpers ----
    void blinkmPlayScript(uint8_t addr, uint8_t id, uint8_t reps, uint8_t pos);
    void blinkmSetFadespeed(uint8_t addr, uint8_t fadespeed);

    // ---- Utility ----
    void statusLedSet(uint8_t val);
    uint8_t statusLedGet();
    void eeSave();
    void eeLoad();
};

extern LinkMHID LinkMDevice;
