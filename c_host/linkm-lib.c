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

// simple cross-platform millis sleep func
void linkm_sleep(uint32_t millis)
{
#ifdef WIN32
            Sleep(millis);
#else
            usleep( millis * 1000);
#endif
}


/**
 * Open up a LinkM for transactions.
 * returns 0 on success, and opened device in "dev"
 * or returns non-zero error that can be decoded with linkm_error_msg()
 * FIXME: what happens when multiple are plugged in?
 */
int linkm_open(usbDevice_t **dev)
{
    //if( *dev != NULL ) {
    //    linkm_close(*dev);
    //}

    return usbhidOpenDevice(dev,
                            IDENT_VENDOR_NUM,  IDENT_VENDOR_STRING,
                            IDENT_PRODUCT_NUM, IDENT_PRODUCT_STRING,
                            1);  // NOTE: '0' means "not using report IDs"
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
    uint8_t buf[200]; // FIXME: correct size?  // FIXME: was static
    int len,err;
    if(linkm_debug>1) {
        printf("linkmcmd: cmd:0x%x, num_send:%d, num_recv:%d\n",
               cmd, num_send, num_recv );
    }
    if( dev==NULL ) {
        return LINKM_ERR_NOTOPEN;
    }
    memset( buf, 0, sizeof(buf));  // debug: zero everything (while testing)
    buf[0] = 1;            // byte 0 : report id, required by usb functions
    buf[1] = START_BYTE;   // byte 1 : start byte
    buf[2] = cmd;          // byte 2 : command
    buf[3] = num_send;     // byte 3 : num bytes to send (starting at byte 1+4)
    buf[4] = num_recv;     // byte 4 : num bytes to recv
    if( buf_send != NULL ) {
        memcpy( buf+5, buf_send, sizeof(buf)-5 );

        if(linkm_debug) hexdump("linkmcmd: ",buf, 16); // print firest few bytes
    }
    // send out the command part of the transaction
    if((err = usbhidSetReport(dev, (char*)buf, REPORT1_SIZE)) != 0) {
        fprintf(stderr, "error writing data: %s\n", linkm_error_msg(err));
        return err;
    }

    // FIXME FIXME FIXME
    // FIXME: shouldn't we always get a response back,
    // so we can view error codes ?
    // also, whats with the buf+3 down there, shouldn't it be buf+2?
    // (don't tell me about report id in byte0, i don't believe it

    // if we should return a response from the command, do it
    if( num_recv !=0 ) {
        linkm_sleep( 50 );
        // FIXME: maybe put delay in here?
        //usleep( millisleep * 1000); // sleep millisecs waiting for response
        memset(buf, 0, sizeof(buf));  // clear out so to more easily see data
        //len = sizeof(buf);
        len = REPORT1_SIZE;
        if((err = usbhidGetReport(dev, 1, (char*)buf, &len)) != 0) {
            fprintf(stderr, "error reading data: %s\n", linkm_error_msg(err));
            return err;
        } else {  // it was good
            // byte 0 is report id
            //// byte 0 is transaction counter ( we can ignore)
            // byte 1 is error code   // FIXME: return this?
            // byte 2 is resp_byte 0
            // byte 3 is resp_byte 1
            // ...
            if(linkm_debug>1) hexdump("linkmcmd resp: ", buf, 16);
            memcpy( buf_recv, buf+2, num_recv );  // byte 0 report id
            return buf[1];                        // byte 1 is error code
        }
        linkm_sleep( 50 );
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
void hexdump(const char* intro, uint8_t *buffer, int len)
{
    int     i;
    FILE    *fp = stdout;
    if( intro!=NULL ) fprintf(fp, intro,NULL);
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

// parse string of:
// "scriptline: 2 0x02 0x63 0x50 0xc9 0x5e"
int parse_scriptlines( char* filename,  scriptline_t* lines )
{
    int i = 0;
    FILE* file = fopen(filename, "r");
    if( file == NULL ) {
        perror("unable to open file");
        exit(1);
    }
    char line[100];
    while( fgets(line, sizeof(line), file) ) {
        printf("\tparse: %d: line:%s", i, line);
        //scriptline_t s = scriptlines[i];
        int pos;
        int n = sscanf( line,
                        "scriptline: %d 0x%02hhx 0x%02hhx 0x%02hhx 0x%02hhx 0x%02hhx",
                        &pos,
                        &lines[i].duration, &lines[i].cmd,
                        &lines[i].arg0, &lines[i].arg1, &lines[i].arg2);
        //printf("    n:%d\n", n);
        if( n==6 ) { // number of fields parsed
            i++;
        }
    }

    fclose(file);
    return i;
}
