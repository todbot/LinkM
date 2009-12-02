/**
 * linkm-lib --
 *
 * 2009, Tod E. Kurt, ThingM, http://thingm.com/
 *
 */

#ifndef __LINKM_LIB_H_INCLUDED__
#define __LINKM_LIB_H_INCLUDED__

#include <stdint.h>
#include "hiddata.h"


#define IDENT_VENDOR_NUM        0x16c0
#define IDENT_PRODUCT_NUM       1503
#define IDENT_VENDOR_STRING     "ThingM"
#define IDENT_PRODUCT_STRING    "LinkM"

#define START_BYTE          0xDA

// Command byte values for linkm_command()
enum { 
    LINKM_CMD_NONE = 0,       // no command, do not use
    // I2C commands
    LINKM_CMD_I2CTRANS,          // i2c read & write (N args: addr + other)
    LINKM_CMD_I2CWRITE,          // i2c write to dev (N args: addr + other)
    LINKM_CMD_I2CREAD,           // i2c read         (1 args: addr)
    LINKM_CMD_I2CSCAN,           // i2c bus scan     (2 args: start,end)
    LINKM_CMD_I2CCONN,           // i2c connect/disc (1 args: 1/0)
    LINKM_CMD_I2CINIT,           // i2c init         (0 args: )

    // linkm board commands
    LINKM_CMD_STATLED = 100,     // status LED set   (1 args: 1/0)
    LINKM_CMD_STATLEDGET,        // status LED get   (0 args)
    LINKM_CMD_PLAYSET            // set up play state machine (FIXME)
};

// Return values for linkm_command()
enum { 
    LINKM_ERR_NONE     =   0,
    LINKM_ERR_BADSTART = 101,
    LINKM_ERR_BADARGS,
    LINKM_ERR_I2C,
    LINKM_ERR_I2CREAD,
    LINKM_ERR_NOTOPEN = 199,
};


extern int linkm_debug;

// public api
int linkm_open(usbDevice_t** dev);
void linkm_close(usbDevice_t* dev);
int linkm_command(usbDevice_t* dev, int cmd, 
                  int bytes_send, int bytes_recv,
                  uint8_t* buf_send, uint8_t* buf_recv);
char* linkm_error_msg(int errCode);

// utility
void hexdump(char* intro, uint8_t* buffer, int len);
int  hexread(uint8_t* buffer, char* string, int buflen);


#endif //__LINKM_LIB_H_INCLUDED__
