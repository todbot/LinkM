/**
 * linkm-lib -- LinkM functions 
 *
 *
 * 2009, Tod E. Kurt, ThingM, http://thingm.com/
 *
 */


#include <stdio.h>
#include <ctype.h>      // for isalpha()
#include <stdlib.h>     // for strtol()
#include <string.h>     // for memset() et al
#include <unistd.h>     // for usleep()

#include "linkm-lib.h"

int linkm_debug = 0;

/**
 * Open up a LinkM for transactions.
 * returns 0 on success, and opened device in "dev"
 * or returns non-zero error that can be decoded with linkm_error_msg()
 * FIXME: what happens when multiple are plugged in?
 */
int linkm_open(usbDevice_t **dev)
{
    return usbhidOpenDevice(dev, 
                            IDENT_VENDOR_NUM,  IDENT_VENDOR_STRING,
                            IDENT_PRODUCT_NUM, IDENT_PRODUCT_STRING,
                            0);  // NOTE: '0' means "not using report IDs"
}

/**
 * Close a LinkM 
 */
void linkm_close(usbDevice_t *dev)
{
    usbhidCloseDevice(dev);
}

/**
 * Given a linkm command, number of bytes to send and receive, 
 * and buffers to read from and write to, do a linkm transaction
 * Make sure buf_recv is big enough to receive data, or it will be truncated
 * return 0 on success, other on failure.
 *
 * This is the most-used function for LinkM tools.
 */
int linkm_command(usbDevice_t *dev, int cmd, 
                  int num_send, int num_recv,
                  uint8_t* buf_send, uint8_t* buf_recv)
{
    static uint8_t buf[129]; // FIXME: correct size?
    int len,err;
    if(linkm_debug>1) {
        printf("linkmcmd: cmd:0x%x, num_send:%d, num_recv:%d\n",
               cmd, num_send, num_recv );
    }
    if( dev==NULL ) {
        return LINKM_ERR_NOTOPEN;
    }
    memset( buf, 0, sizeof(buf));  // debug: zero everything (while testing)
    buf[0] = 0;            // byte 0 : report id, required by usb functions
    buf[1] = START_BYTE;   // byte 1 : start byte
    buf[2] = cmd;          // byte 2 : command
    buf[3] = num_send;     // byte 3 : num bytes to send (starting at byte 1+4) 
    buf[4] = num_recv;     // byte 4 : num bytes to recv 
    if( buf_send != NULL ) {
        memcpy( buf+5, buf_send, sizeof(buf)-5 );
        
        if(linkm_debug) hexdump("linkmcmd: ",buf, 16); // print firest few bytes
    }
    // send out the command part of the transaction
    if((err = usbhidSetReport(dev, (char*)buf, sizeof(buf))) != 0) {
        fprintf(stderr, "error writing data: %s\n", linkm_error_msg(err));
        return err;
    }
    // if we should return a response from the command, do it
    if( num_recv !=0 ) {
        // FIXME: maybe put delay in here?
        //usleep( millisleep * 1000); // sleep millisecs waiting for response
        memset(buf, 0, sizeof(buf));  // clear out so to more easily see data
        len = sizeof(buf);
        if((err = usbhidGetReport(dev, 0, (char*)buf, &len)) != 0) {
            fprintf(stderr, "error reading data: %s\n", linkm_error_msg(err));
            return err;
        } else {  // it was good
            // byte 0 is transaction counter ( we can ignore)
            // byte 1 is error code   // FIXME: return this?
            // byte 2 is resp_byte 0
            // byte 3 is resp_byte 1
            // ...
            if(linkm_debug>1) hexdump("linkmcmd resp: ", buf, 16);
            memcpy( buf_recv, buf+3, num_recv );  // 1st byte report id
            return buf[2];  // byte 1 is error code
        }
    }
    return 0;
}

/**
 * decodes error messages into string
 */
char* linkm_error_msg(int errCode)
{
    static char buffer[80];

    switch(errCode){
    case USBOPEN_ERR_ACCESS:      return "Access to device denied";
    case USBOPEN_ERR_NOTFOUND:    return "LinkM, not found";
    case USBOPEN_ERR_IO:          return "Communication error with device";
    case LINKM_ERR_BADSTART:      return "LinkM, bad start byte";
    case LINKM_ERR_BADARGS:       return "LinkM, improper args for command";
    case LINKM_ERR_I2C:           return "LinkM, I2C error";
    case LINKM_ERR_I2CREAD:       return "LinkM, I2C read error";
    case LINKM_ERR_NOTOPEN:       return "LinkM not opened";
    default:
        sprintf(buffer, "Unknown USB error %d", errCode);
        return buffer;
    }
    return NULL;    // not reached 
}

/* ------------------------------------------------------------------------- */
/*  Utility funcs */

/**
 * Print out a buffer as a hex string, with an optional intro string
 */
void hexdump(char* intro, uint8_t *buffer, int len)
{
    int     i;
    FILE    *fp = stdout;
    if( intro!=NULL ) fprintf(fp, intro);
    for(i = 0; i < len; i++) {
        fprintf(fp, ((i%16)==0) ? ((i==0)?"":"\n"):" ");
        fprintf(fp, "0x%02x", buffer[i]);
    }
    //if(i != 0)
    fprintf(fp, "\n");
}

/**
 * Read a hex-formatted values from a string into a buffer
 */
int  hexread(uint8_t *buffer, char *string, int buflen)
{
    char    *s;
    int     pos = 0;   
    while((s = strtok(string, ", '\"")) != NULL && pos < buflen) {
        string = NULL;
        buffer[pos++] = (isalpha(*s)) ? *s : (char)strtol(s, NULL, 0);
    }
    return pos;
}


