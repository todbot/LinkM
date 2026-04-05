/**
 * linkm_protocol.h -- LinkM USB HID protocol constants
 *
 * Mirrors c_host/linkm-lib.h so numeric values stay in sync.
 * 2009, Tod E. Kurt, ThingM, http://thingm.com/
 */

#pragma once
#include <stdint.h>

#define START_BYTE          0xDA

#define LINKM_VERSION_MAJOR 0x13
#define LINKM_VERSION_MINOR 0x36

#define REPORT1_COUNT       8   // HID report size (response / HID descriptor)
#define REPORT1_RXSIZE     16   // receive buffer: full payload minus report ID byte
                                // host sends REPORT1_SIZE=17: [report_id][16 bytes]

// Command byte values
enum {
    LINKM_CMD_NONE       = 0,
    LINKM_CMD_I2CTRANS   = 1,   // I2C write + optional read
    LINKM_CMD_I2CWRITE   = 2,   // I2C write only
    LINKM_CMD_I2CREAD    = 3,   // I2C read only
    LINKM_CMD_I2CSCAN    = 4,   // I2C bus scan
    LINKM_CMD_I2CCONN    = 5,   // I2C bus connect/disconnect
    LINKM_CMD_I2CINIT    = 6,   // I2C re-initialize

    LINKM_CMD_VERSIONGET = 100, // get LinkM firmware version
    LINKM_CMD_STATLEDSET = 101, // set status LED on/off
    LINKM_CMD_STATLEDGET = 102, // get status LED state
    LINKM_CMD_PLAYSET    = 103, // set playback state machine params
    LINKM_CMD_PLAYGET    = 104, // get playback state machine params
    LINKM_CMD_EESAVE     = 105, // save params to EEPROM
    LINKM_CMD_EELOAD     = 106, // load params from EEPROM
    LINKM_CMD_GOBOOTLOAD = 107, // enter USB bootloader
};

// Error codes (returned in txBuf[1])
enum {
    LINKM_ERR_NONE     =   0,
    LINKM_ERR_BADSTART = 101,   // START_BYTE (0xDA) not found
    LINKM_ERR_BADARGS  = 102,   // invalid arguments
    LINKM_ERR_I2C      = 103,   // I2C START failed (no ACK)
    LINKM_ERR_I2CREAD  = 104,   // I2C read failed
    LINKM_ERR_NOTOPEN  = 199,   // host-side only
};
