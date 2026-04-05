/**
 * LinkMHID.cpp -- Arduino Pro Micro (ATmega32U4) LinkM emulator
 *
 * Implements USB HID feature-report protocol identical to the original
 * LinkM firmware (ATmega88P + V-USB).  All communication uses HID
 * SET_REPORT / GET_REPORT control transfers (Report ID 1, 8 bytes).
 * I2C is driven by the Wire library at 100 kHz.
 *
 * 2009/2025, Tod E. Kurt, ThingM, http://thingm.com/
 */

#include "LinkMHID.h"
#include <EEPROM.h>

// HID report descriptor — must match original firmware exactly (33 bytes)
// Defines a single vendor feature report: ID=1, 8 bytes.
static const uint8_t PROGMEM _hidReportDescriptor[33] = {
    0x06, 0x00, 0xff,   // USAGE_PAGE (Vendor-defined 0xFF00)
    0x09, 0x01,         // USAGE (Vendor Usage 1)
    0xa1, 0x01,         // COLLECTION (Application)
    0x15, 0x00,         //   LOGICAL_MINIMUM (0)
    0x26, 0xff, 0x00,   //   LOGICAL_MAXIMUM (255)
    0x75, 0x08,         //   REPORT_SIZE (8 bits)
    0x85, 0x01,         //   REPORT_ID (1)
    0x95, 0x08,         //   REPORT_COUNT (8)
    0x09, 0x00,         //   USAGE (Undefined)
    0xb2, 0x02, 0x01,   //   FEATURE (Data,Var,Abs,Buf)
    0xc0                // END_COLLECTION
};

// ---- Constructor ----

LinkMHID::LinkMHID() : PluggableUSBModule(1, 1, epType), msgReady(false),
                       script_pos(0), lastTickMs(0) {
    epType[0] = EP_TYPE_INTERRUPT_IN;
    // Pre-clear buffers; txBuf[0]=1 (report ID echo) stays constant
    memset(rxBuf, 0, sizeof(rxBuf));
    memset(txBuf, 0, sizeof(txBuf));
    txBuf[0] = 1;
    memset(&params, 0, sizeof(params));
    params.fadespeed = 100;  // default — matches original EEPROM init
    PluggableUSB().plug(this);
}

// ---- Public API ----

void LinkMHID::begin() {
    pinMode(LED_BUILTIN, OUTPUT);
    statusLedSet(0);
    Wire.begin();
    Wire.setClock(100000);
    eeLoad();
    // If a non-zero fadespeed was loaded, push it to BlinkM address 0
    if (params.fadespeed != 0) {
        blinkmSetFadespeed(0, params.fadespeed);
    }
}

void LinkMHID::processIfReady() {
    if (!msgReady) return;
    handleMessage();
    msgReady = false;
}

void LinkMHID::playTicker() {
    if (!params.playing || params.script_tick == 0) return;
    uint32_t stepMs = (uint32_t)params.script_tick * TICK_MS;
    if ((uint32_t)(millis() - lastTickMs) >= stepMs) {
        lastTickMs = millis();
        blinkmPlayScript(0, params.script_id, 0, (uint8_t)script_pos);
        statusLedSet(1); delayMicroseconds(500); statusLedSet(0);
        if (++script_pos >= params.script_len) script_pos = 0;
    }
}

// ---- PluggableUSBModule: configuration descriptor contribution ----
//
// Writes a 25-byte block: Interface (9) + HID class (9) + Endpoint (7).
// One interrupt-in endpoint is declared so Windows HID enumeration succeeds;
// we never actually send data on it.

int LinkMHID::getInterface(uint8_t* interfaceCount) {
    *interfaceCount += 1;
    LinkMIfaceDescriptor desc = {
        // Interface descriptor
        9,                              // bLength
        0x04,                           // bDescriptorType = INTERFACE
        (uint8_t)pluggedInterface,      // bInterfaceNumber
        0,                              // bAlternateSetting
        1,                              // bNumEndpoints (one interrupt-in)
        0x03,                           // bInterfaceClass = HID
        0x00,                           // bInterfaceSubClass = none
        0x00,                           // bInterfaceProtocol = none
        0,                              // iInterface = no string
        // HID class descriptor (type 0x21)
        9,                              // bLength
        HID_DESCRIPTOR_TYPE,            // bDescriptorType = HID (0x21)
        0x11, 0x01,                     // bcdHID = 1.11 (little-endian)
        0x00,                           // bCountryCode = not localised
        1,                              // bNumDescriptors
        HID_REPORT_DESCRIPTOR_TYPE,     // bDescriptorType = Report (0x22)
        (uint8_t)(sizeof(_hidReportDescriptor) & 0xFF),
        (uint8_t)(sizeof(_hidReportDescriptor) >> 8),
        // Endpoint descriptor
        7,                              // bLength
        0x05,                           // bDescriptorType = ENDPOINT
        (uint8_t)(USB_ENDPOINT_IN(pluggedEndpoint)), // bEndpointAddress
        0x03,                           // bmAttributes = Interrupt
        USB_EP_SIZE, 0,                 // wMaxPacketSize
        0xFF,                           // bInterval = 255 ms (max; never polled)
    };
    return USB_SendControl(0, &desc, sizeof(desc));
}

// ---- PluggableUSBModule: handle GET_DESCRIPTOR for HID report descriptor ----

int LinkMHID::getDescriptor(USBSetup& setup) {
    // Only respond to Standard GET_DESCRIPTOR targeted at our interface
    if (setup.bmRequestType != 0x81) return 0;  // Standard | Interface | D→H
    if (setup.wValueH != HID_REPORT_DESCRIPTOR_TYPE) return 0;
    if (setup.wIndex  != pluggedInterface) return 0;
    return USB_SendControl(TRANSFER_PGM,
                           _hidReportDescriptor,
                           sizeof(_hidReportDescriptor));
}

uint8_t LinkMHID::getShortName(char* name) {
    name[0] = 'L'; name[1] = 'M';
    return 2;
}

// ---- PluggableUSBModule: handle HID class control transfers ----
//
// SET_REPORT (host→device): read 8 bytes into rxBuf, set msgReady.
// GET_REPORT (device→host): send current txBuf (8 bytes).
//
// IMPORTANT: USB_RecvControl() must be called here, inside the USB interrupt
// context.  The data stage of the control transfer is consumed immediately;
// deferring the read to loop() would miss the data.  Only handleMessage()
// (the I2C work) is deferred to loop() via the msgReady flag.

bool LinkMHID::setup(USBSetup& setup) {

    // Accept requests addressed to our interface or to the device as a whole.
    // hiddata.c (the LinkM host library) sends wIndex=0 / RECIPIENT_DEVICE;
    // the HID spec says wIndex should be the interface number, so accept both.
    if (setup.wIndex != 0 && setup.wIndex != pluggedInterface) return false;

    uint8_t reqType    = setup.bmRequestType;
    uint8_t req        = setup.bRequest;
    uint8_t reportId   = setup.wValueL;   // low byte: report ID
    uint8_t reportType = setup.wValueH;   // high byte: 1=INPUT 2=OUTPUT 3=FEATURE

    bool isHostToDevice = (reqType == REQ_HOST_TO_DEVICE_CLASS ||
                           reqType == REQ_HOST_TO_DEVICE_CLASS_IF);
    bool isDeviceToHost = (reqType == REQ_DEVICE_TO_HOST_CLASS ||
                           reqType == REQ_DEVICE_TO_HOST_CLASS_IF);

    // --- SET_REPORT: host sends command to us ---
    if (isHostToDevice && req == HID_SET_REPORT) {
        if (reportType == HID_REPORT_TYPE_FEATURE && reportId == 1) {
            // The host (hiddata.c, usesReportIDs=1) prepends the report ID byte
            // to the data stage: [0x01][START_BYTE][cmd]...[padding] = 17 bytes.
            // We must read at least enough bytes to clear the FIFO, and skip
            // the leading report ID byte so rxBuf[0] aligns with START_BYTE.
            uint8_t tmp[17];
            uint8_t n = (setup.wLength <= 17) ? (uint8_t)setup.wLength : 17;
            USB_RecvControl(tmp, n);
            memcpy(rxBuf, tmp + 1, REPORT1_RXSIZE);  // tmp[0]=report_id; skip it
            msgReady = true;
            return true;
        }
    }

    // --- GET_REPORT: host reads our response ---
    if (isDeviceToHost && req == HID_GET_REPORT) {
        if (reportType == HID_REPORT_TYPE_FEATURE && reportId == 1) {
            USB_SendControl(0, txBuf, REPORT1_COUNT);
            return true;
        }
    }

    // --- SET_IDLE: sent by some hosts during enumeration; ACK silently ---
    if (isHostToDevice && req == HID_SET_IDLE) {
        return true;
    }

    return false;
}

// ---- Command dispatcher ----

void LinkMHID::handleMessage() {
    // Clear response buffer; txBuf[0] stays 1 (report ID echo)
    memset(txBuf + 1, 0, REPORT1_COUNT - 1);
    txBuf[0] = 1;
    txBuf[1] = LINKM_ERR_NONE;

    // rxBuf layout (report ID already stripped by USB stack):
    //   [0] START_BYTE (0xDA)
    //   [1] command
    //   [2] num_sent  (bytes to write to I2C; I2C addr counts as 1)
    //   [3] num_recv  (bytes to read from I2C)
    //   [4] arg0 / I2C address
    //   [5] arg1 / data byte 0
    //   [6] arg2 / data byte 1
    //   [7] arg3 / data byte 2

    if (rxBuf[0] != START_BYTE) {
        txBuf[1] = LINKM_ERR_BADSTART;
        return;
    }

    statusLedSet(1);
    uint8_t cmd = rxBuf[1];
    bool preserveLed = false;

    switch (cmd) {
    case LINKM_CMD_I2CTRANS:   doI2CTrans();  break;
    case LINKM_CMD_I2CWRITE:   doI2CWrite();  break;
    case LINKM_CMD_I2CREAD:    doI2CRead();   break;
    case LINKM_CMD_I2CSCAN:    doI2CScan();   break;

    case LINKM_CMD_I2CCONN:
        // No-op: Pro Micro has no I2C buffer chip to enable/disable
        break;

    case LINKM_CMD_I2CINIT:
        Wire.end();
        Wire.begin();
        Wire.setClock(100000);
        break;

    case LINKM_CMD_VERSIONGET:
        txBuf[2] = LINKM_VERSION_MAJOR;
        txBuf[3] = LINKM_VERSION_MINOR;
        break;

    case LINKM_CMD_STATLEDSET:
        statusLedSet(rxBuf[4]);
        preserveLed = true;  // don't extinguish what was just set
        break;

    case LINKM_CMD_STATLEDGET:
        txBuf[2] = statusLedGet();
        break;

    case LINKM_CMD_PLAYSET:
        // Only 4 param bytes fit in indices [4..7] of the 8-byte buffer.
        // This covers: playing, script_id, script_tick, script_len.
        // start_pos, fadespeed, dir must come via separate commands if needed.
        memcpy(&params, &rxBuf[4], min((size_t)(REPORT1_COUNT - 4), sizeof(params)));
        script_pos = params.start_pos;
        if (params.fadespeed != 0) {
            blinkmSetFadespeed(0, params.fadespeed);
        }
        break;

    case LINKM_CMD_PLAYGET:
        // Return up to 6 bytes (indices [2..7]) of the 7-byte params struct
        memcpy(&txBuf[2], &params, min(sizeof(params), (size_t)(REPORT1_COUNT - 2)));
        break;

    case LINKM_CMD_EESAVE:
        statusLedSet(1);
        eeSave();
        statusLedSet(0);
        break;

    case LINKM_CMD_EELOAD:
        statusLedSet(1);
        eeLoad();
        statusLedSet(0);
        break;

    case LINKM_CMD_GOBOOTLOAD:
        // Trigger Caterina bootloader via magic key then watchdog reset
        // Matches MAGIC_KEY/MAGIC_KEY_POS defined in Arduino USBCore.h
        *(uint16_t *)0x0800 = 0x7777;
        wdt_enable(WDTO_15MS);
        while (1) {}
        break;

    default:
        break;
    }

    if (!preserveLed) statusLedSet(0);
}

// ---- I2C command implementations ----

void LinkMHID::doI2CTrans() {
    uint8_t addr     = rxBuf[4];
    uint8_t num_sent = rxBuf[2];  // includes addr as 1 byte
    uint8_t num_recv = rxBuf[3];

    if (addr >= 0x80) { txBuf[1] = LINKM_ERR_BADARGS; return; }

    Wire.beginTransmission(addr);
    // num_sent - 1 data bytes follow the address (rxBuf[5] onward)
    for (uint8_t i = 0; i < num_sent - 1; i++) {
        Wire.write(rxBuf[5 + i]);
    }
    // sendStop=false → repeated START if we need to read back
    uint8_t err = Wire.endTransmission(num_recv == 0);
    if (err != 0) { txBuf[1] = LINKM_ERR_I2C; return; }

    if (num_recv > 0) {
        uint8_t got = Wire.requestFrom((uint8_t)addr, num_recv);
        if (got != num_recv) { txBuf[1] = LINKM_ERR_I2CREAD; return; }
        for (uint8_t i = 0; i < num_recv; i++) {
            txBuf[2 + i] = Wire.read();
        }
    }
}

void LinkMHID::doI2CWrite() {
    uint8_t addr     = rxBuf[4];
    uint8_t doread   = rxBuf[5];  // 1 = keep bus open for a subsequent read
    uint8_t num_sent = rxBuf[2];

    if (addr >= 0x80) { txBuf[1] = LINKM_ERR_BADARGS; return; }

    Wire.beginTransmission(addr);
    for (uint8_t i = 0; i < num_sent - 1; i++) {
        Wire.write(rxBuf[5 + i]);
    }
    // sendStop=false if the host plans a subsequent I2CREAD on the same device
    Wire.endTransmission(!doread);
    // Note: error ignored here to match original firmware behaviour
}

void LinkMHID::doI2CRead() {
    uint8_t addr     = rxBuf[4];
    uint8_t num_recv = rxBuf[3];

    if (num_recv == 0) { txBuf[1] = LINKM_ERR_BADARGS; return; }

    uint8_t got = Wire.requestFrom((uint8_t)addr, num_recv);
    if (got != num_recv) { txBuf[1] = LINKM_ERR_I2CREAD; return; }
    for (uint8_t i = 0; i < num_recv; i++) {
        txBuf[2 + i] = Wire.read();
    }
}

void LinkMHID::doI2CScan() {
    uint8_t start = rxBuf[4];
    uint8_t end   = rxBuf[5];

    if (start >= 0x80 || end >= 0x80 || start > end) {
        txBuf[1] = LINKM_ERR_BADARGS;
        return;
    }

    uint8_t numfound = 0;
    for (uint8_t a = start; a < end; a++) {
        Wire.beginTransmission(a);
        uint8_t err = Wire.endTransmission();
        if (err == 0) {
            // Guard txBuf bounds: addresses stored starting at [3]
            if (3 + numfound < REPORT1_COUNT) {
                txBuf[3 + numfound] = a;
            }
            numfound++;
        }
    }
    txBuf[2] = numfound;
}

// ---- BlinkM helper commands ----

void LinkMHID::blinkmPlayScript(uint8_t addr, uint8_t id,
                                uint8_t reps, uint8_t pos) {
    Wire.beginTransmission(addr);
    Wire.write('p');
    Wire.write(id);
    Wire.write(reps);
    Wire.write(pos);
    Wire.endTransmission();
}

void LinkMHID::blinkmSetFadespeed(uint8_t addr, uint8_t fadespeed) {
    Wire.beginTransmission(addr);
    Wire.write('f');
    Wire.write(fadespeed);
    Wire.endTransmission();
}

// ---- Utility ----

void LinkMHID::statusLedSet(uint8_t val) {
    digitalWrite(LED_BUILTIN, val ? HIGH : LOW);
}

uint8_t LinkMHID::statusLedGet() {
    return digitalRead(LED_BUILTIN) ? 1 : 0;
}

void LinkMHID::eeSave() {
    EEPROM.put(EE_PARAMS_ADDR, params);
}

void LinkMHID::eeLoad() {
    EEPROM.get(EE_PARAMS_ADDR, params);
    // Fresh/blank EEPROM reads as 0xFF — reset to safe defaults
    if (params.script_tick == 0xFF) {
        memset(&params, 0, sizeof(params));
        params.fadespeed = 100;
    }
}
