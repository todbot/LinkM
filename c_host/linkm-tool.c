/*
 * linkm-tool -- Command-line tool for using LinkM.
 *               Also excercises the linkm-lib library.
 *
 *
 * Based off of "hidtool", part of the "vusb" AVR-USB library by obdev
 *
 * 2009, Tod E. Kurt, ThingM, http://thingm.com/
 *
 */

/*
 *./linkm-tool -v --linkmcmd "0x01,4,5,12,'R',0,2"
linkm command:
linkmcmd: 0x00 0xda 0x01 0x04 0x05 0x0c 0x52 0x00 0x02 0x00 0x00 0x00 0x00 0x00 0x00 0x00
resp: 0x00 0x09 0x00 0x32 0x63 0x8a 0x00 0x00 0x00 0xde 0xad 0xbe 0xef 0x60 0x61 0x62
recv: 0x32 0x63 0x8a 0x00 0x00 0x8f 0x84 0xf6 0xff 0xbf 0x04 0x00 0x00 0x00 0x58 0xf6
*/

// FIXME: what happens when multiple are plugged in?

#include <stdio.h>
#include <string.h>    // for memcpy() et al
#include <stdlib.h>    // for rand() & strtol()
#include <getopt.h>    // for getopt_long()
#include <unistd.h>    // for usleep()
#include <ctype.h>     // for isalpha()
#include <time.h>      // for time()

#include "linkm-lib.h"


static int debug = 0;

// local states for the "cmd" option variable
enum { 
    CMD_NONE = 0,
    CMD_LINKM_READ,
    CMD_LINKM_WRITE,
    CMD_LINKM_CMD,
    CMD_LINKM_STATLED,
    CMD_LINKM_I2CSCAN,
    CMD_LINKM_I2CENABLE,
    CMD_LINKM_I2CINIT,
    CMD_BLINKM_CMD,
    CMD_BLINKM_OFF,
    CMD_BLINKM_PLAY,
    CMD_BLINKM_STOP,
    CMD_BLINKM_COLOR,
    CMD_BLINKM_UPLOAD,
    CMD_BLINKM_DOWNLOAD,
    CMD_BLINKM_READINPUTS,
    CMD_BLINKM_SETADDR,
    CMD_BLINKM_GETVERSION,
    CMD_BLINKM_RANDOM,
};

/* ------------------------------------------------------------------------- */

void usage(char *myName)
{
    printf(
"Usage: %s <cmd> [options]\n"
"\n"
"where <cmd> is one of:\n"
"  --cmd <blinkmcmd> Send a blinkm command  \n"
"  --off             Turn off blinkm at specified address (or all) \n"
"  --play <n>        Play light script N \n"
"  --stop            Stop playing light script \n"
"  --getversion      Gets BlinkM version \n"
"  --setaddr <newa>  Set address of blinkm at address 'addr' to 'newa' \n"
"  --random <n>      Send N random colors to blinkm\n"
"  --i2cscan         Scan I2c bus for devices  \n"
"  --i2enable <0|1>  Enable or disable the I2C bus (for connecting devices) \n"
"  --upload          Upload a light script to blinkm (reqs addr & file) \n"
"  --download <n>    Download light script n from blinkm (reqs addr & file) \n"
"  --readinputs      Read inputs (on MaxM)\n"
"  --linkmcmd        Send a raw linkm command  \n"
"  --statled <0|1>   Turn on or off status LED  \n"
"Options:\n"
"  -h, --help                   Print this help message\n"
"  -a addr, --addr=i2caddr      I2C address for command (default 0)\n"
"  -f file, --afile=file        Read or save to this file\n"
"  -m ms,   --miilis=millis     Set millisecs betwen actions (default 100)\n"
"  -v, --verbose                verbose debugging msgs\n"
"\n"
"Note:  blah blah blah\n"
"\n", myName
           );
    exit(1);
}


/**
 * dun dun DUN
 */
int main(int argc, char **argv)
{
    usbDevice_t *dev;
    int err;

    // this needs to be a global int for getopt_long
    static int cmd  = CMD_NONE;
    int8_t arg  = 0;
    char addr = 0;
    //long color  = 0;
    //int num = 1;
    int millis  = 100;
    char file[255];

    uint8_t buffer[65];  // room for dummy report ID  (this will go away soon?)
    uint8_t cmdbuf[64];  // blinkm command buffer
    uint8_t recvbuf[64];
    int len;

    memset(cmdbuf,0,sizeof(cmdbuf));  // zero out for debugging ease

    srand( time(0) );    // a good enough seeding for our purposes

    if(argc < 2){
        usage(argv[0]);
    }

    // parse options
    int option_index = 0, opt;
    char* opt_str = "a:df:m:v";
    static struct option loptions[] = {
        {"addr",       required_argument, 0,      'a'},
        {"debug",      optional_argument, 0,      'd'},
        {"file",       required_argument, 0,      'f'},
        {"millis",     required_argument, 0,      'm'},
        {"verbose",    optional_argument, 0,      'v'},
        {"linkmread",  no_argument,       &cmd,   CMD_LINKM_READ },
        {"linkmwrite", required_argument, &cmd,   CMD_LINKM_WRITE },
        {"linkmcmd",   required_argument, &cmd,   CMD_LINKM_CMD },
        {"statled",    required_argument, &cmd,   CMD_LINKM_STATLED },
        {"i2cscan",    no_argument,       &cmd,   CMD_LINKM_I2CSCAN },
        {"i2cenable",  required_argument, &cmd,   CMD_LINKM_I2CENABLE },
        {"i2cinit",    no_argument,       &cmd,   CMD_LINKM_I2CINIT },
        {"cmd",        required_argument, &cmd,   CMD_BLINKM_CMD },
        {"off",        no_argument,       &cmd,   CMD_BLINKM_OFF },
        {"stop",       no_argument,       &cmd,   CMD_BLINKM_STOP },
        {"play",       required_argument, &cmd,   CMD_BLINKM_PLAY },
        {"color",      required_argument, &cmd,   CMD_BLINKM_COLOR },
        {"upload",     required_argument, &cmd,   CMD_BLINKM_UPLOAD },
        {"download",   required_argument, &cmd,   CMD_BLINKM_DOWNLOAD },
        {"readinputs", no_argument,       &cmd,   CMD_BLINKM_READINPUTS },
        {"random",     required_argument, &cmd,   CMD_BLINKM_RANDOM },
        {"setaddr",    required_argument, &cmd,   CMD_BLINKM_SETADDR },
        {"getversion", no_argument,       &cmd,   CMD_BLINKM_GETVERSION },
        {NULL,         0,                 0,      0}
    };

    while(1) {
        opt = getopt_long (argc, argv, opt_str, loptions, &option_index);
        if (opt==-1) break; // parsed all the args
        switch (opt) {
        case 0:             // deal with long opts that have no short opts
            switch(cmd) { 
            case CMD_LINKM_WRITE:
            case CMD_LINKM_CMD:
            case CMD_BLINKM_CMD:
                hexread(cmdbuf, optarg, sizeof(cmdbuf));
                break;
            case CMD_LINKM_STATLED:
            case CMD_LINKM_I2CENABLE:
            case CMD_BLINKM_RANDOM:
            case CMD_BLINKM_SETADDR:
            case CMD_BLINKM_PLAY:
                arg = strtol(optarg,NULL,0);
                break;
            }
            break;
        case 'a':
            addr = strtol(optarg,NULL,0);
            break;
        case 'f':
            strcpy(file,optarg);
            break;
        case 'm':
            millis = strtol(optarg,NULL,10);
            break;
        case 'v':
        case 'd':
            if( optarg==NULL ) debug++;
            else debug = strtol(optarg,NULL,0);
        default:
            break;
        }
    }
    
    if( cmd == CMD_NONE ) usage(argv[0]);   // just in case
    linkm_debug = debug;

    // open up linkm, get back a 'dev' to pass around
    if( (err = linkm_open( &dev )) ) {
        fprintf(stderr, "Error opening LinkM: %s\n", linkm_error_msg(err));
        exit(1);
    }
    
    // perform commanded action
    if( cmd == CMD_LINKM_READ ) {  // low-level read linkm buffer
        printf("linkm read:\n");
        memset( buffer, 0, sizeof(buffer));
        len = sizeof(buffer);
        if((err = usbhidGetReport(dev, 0, (char*)buffer, &len)) != 0) {
            fprintf(stderr, "error reading data: %s\n", linkm_error_msg(err));
        } else {
            hexdump("", buffer + 1, sizeof(buffer) - 1);
        }
    }
    else if( cmd == CMD_LINKM_WRITE ) {  // low-level write linkm buffer
        printf("linkm write:\n");
        memset( buffer, 0, sizeof(buffer));
        memcpy( buffer+1, cmdbuf, sizeof(cmdbuf) );
        if(debug) hexdump("linkm write: ", buffer, 16); // print first bytes 
        if((err = usbhidSetReport(dev, (char*)buffer, sizeof(buffer))) != 0) {
            fprintf(stderr, "error writing data: %s\n", linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_CMD ) {   // low-level linkm command
        printf("linkm command:\n");
        char cmdbyte  = cmdbuf[0];     // this is kind of dumb
        char num_send = cmdbuf[1];
        char num_recv = cmdbuf[2];
        uint8_t* cmdbufp = cmdbuf + 3;  // move along nothing to see here
        err = linkm_command(dev, cmdbyte, num_send,num_recv, cmdbufp,recvbuf);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
        else {  // success
            if( num_recv ) hexdump("recv: ", recvbuf, 16);
        }
    }
    else if( cmd == CMD_LINKM_STATLED ) {    // control LinkM's status LED 
        err = linkm_command(dev, LINKM_CMD_STATLED, 1,0,  (uint8_t*)&arg,NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_I2CENABLE ) {    // control LinkM's I2C enable
        err = linkm_command(dev, LINKM_CMD_I2CCONN, 1,0,  (uint8_t*)&arg,NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_I2CINIT ) {    // restart LinkM's I2C software
        err = linkm_command(dev, LINKM_CMD_I2CINIT, 0,0,  NULL,NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_I2CSCAN ) { 
        if( addr == 0 ) addr = 1;
        printf("i2c scan from addresses %d - %d\n", addr, addr+16);
        cmdbuf[0] = addr;     // start address: 01
        cmdbuf[1] = addr+16;  // end address:   16
        err = linkm_command(dev, LINKM_CMD_I2CSCAN, 2, 16, cmdbuf, recvbuf);
        if( err ) {
            fprintf(stderr,"error on i2c scan: %s\n",linkm_error_msg(err));
        }
        else {
            if(debug) hexdump("recvbuf:", recvbuf, 16);
            int cnt = recvbuf[0];
            if( cnt == 0 ) {
                printf("no I2C devices found\n");
            } else { 
                for( int i=0; i< cnt; i++ ) {
                    printf("device found at address %d\n",recvbuf[1+i]);
                }
            }
        }
    }
    else if( cmd == CMD_BLINKM_CMD ) {   // send arbitrary blinkm command
        printf("addr %d: sending cmd:%c,0x%02x,0x%02x,0x%02x\n",addr,
               cmdbuf[0],cmdbuf[1],cmdbuf[2],cmdbuf[3]);
        // fixme: check that 'b'yte array arg was used
        memmove( cmdbuf+1, cmdbuf, sizeof(cmdbuf)-1 );  // move over for addr
        cmdbuf[0] = addr;
        // do i2c transaction (0x01) with no recv
        err = linkm_command(dev, LINKM_CMD_I2CTRANS, 5,0, cmdbuf, NULL );
        if( err ) {
            fprintf(stderr,"error on blinkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_BLINKM_GETVERSION ) {
        printf("addr:%d: getting version\n", addr );
        cmdbuf[0] = addr;
        cmdbuf[1] = 'Z';
        err = linkm_command(dev, LINKM_CMD_I2CTRANS, 2, 2, cmdbuf, recvbuf);
        if( err ) {
            fprintf(stderr,"error on getversion: %s\n",linkm_error_msg(err));
        }
        else { 
            printf("version: %c,%c\n", recvbuf[0],recvbuf[1]);
        }
    }
    else if( cmd == CMD_BLINKM_SETADDR ) { 
        printf("setting addr from %d to %d\n", addr, arg );
        cmdbuf[0] = addr; // send to old address (or zero for broadcast)
        cmdbuf[1] = 'A';
        cmdbuf[2] = arg;  // arg is new address
        cmdbuf[3] = 0xd0;
        cmdbuf[4] = 0x0d;
        cmdbuf[5] = arg;
        err = linkm_command(dev, LINKM_CMD_I2CTRANS, 6,0,cmdbuf, NULL);
        if( err ) {
            fprintf(stderr,"error on setatt cmd: %s\n",linkm_error_msg(err));
        }
    }
    /*
    else if( cmd == CMD_BLINKM_COLOR ) {
        printf("addr %d: fading to color %02x%02x%02x\n",addr,r,g,b);
        cmdbuf[0] = addr;
        cmdbuf[1] = 'c';
        cmdbuf[2] = r;
        cmdbuf[3] = g;
        cmdbuf[4] = b;
        err = linkm_command(dev, 0x01, 5,0, cmdbuf, NULL );
        if( err ) {
            fprintf(stderr,"error on color cmd: %s\n",linkm_error_msg(err));
        }
    }
    */
    else if( cmd == CMD_BLINKM_RANDOM  ) {
        printf("addr %d: %d random every %d millis\n", addr,arg,millis);
        for( int j=0; j< arg; j++ ) {
            uint8_t r = rand() % 255;    // random() not avail on MinGWindows
            uint8_t g = rand() % 255;
            uint8_t b = rand() % 255;
            cmdbuf[0] = addr;
            cmdbuf[1] = 'n';    // go to color now
            cmdbuf[2] = r;
            cmdbuf[3] = g;
            cmdbuf[4] = b;
            err = linkm_command(dev, LINKM_CMD_I2CTRANS, 5,0, cmdbuf, NULL );
            if( err ) {
                fprintf(stderr,"error on rand cmd: %s\n",linkm_error_msg(err));
                break;
            }
            usleep(millis * 1000 ); // sleep milliseconds
        }
    }
    else if( cmd == CMD_BLINKM_PLAY  ) {
        printf("addr %d: playing script #%d\n", addr,arg);
        cmdbuf[0] = addr; 
        cmdbuf[1] = 'p';  // play script
        cmdbuf[2] = arg;
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 3,0, cmdbuf, NULL)) ) 
            fprintf(stderr,"error on play: %s\n",linkm_error_msg(err));
    }
    else if( cmd == CMD_BLINKM_STOP  ) {
        printf("addr %d: stopping scriptn", addr);
        cmdbuf[0] = addr; 
        cmdbuf[1] = 'o';  // stop script
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 2,0, cmdbuf, NULL)) ) 
            fprintf(stderr,"error on stop: %s\n",linkm_error_msg(err));
    }
    else if( cmd == CMD_BLINKM_OFF  ) {
        printf("addr %d: turning off\n", addr);
        cmdbuf[0] = addr; 
        cmdbuf[1] = 'o';  // stop script
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 2,0, cmdbuf, NULL)) ) 
            fprintf(stderr,"error on blinkmoff cmd: %s\n",linkm_error_msg(err));
        cmdbuf[1] = 'n';  // set rgb color now now
        cmdbuf[2] = cmdbuf[3] = cmdbuf[4] = 0x00;   // to zeros
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 5,0, cmdbuf, NULL)) ) 
            fprintf(stderr,"error on blinkmoff cmd: %s\n",linkm_error_msg(err));
    }
    else if( cmd == CMD_BLINKM_DOWNLOAD ) { 
        if( addr == 0 ) {
            printf("Must specify non-zero address for download\n");
            goto shutdown;
        }
        printf("addr %d: downloading script %d\n", addr,arg);
        uint8_t pos = 0;
        while( pos < 49 ) {
            cmdbuf[0] = addr;
            cmdbuf[1] = 'R';    // go to color now
            cmdbuf[2] = arg;
            cmdbuf[3] = pos;
            err = linkm_command(dev, LINKM_CMD_I2CTRANS, 4,5, cmdbuf, recvbuf );
            if( err ) {
                fprintf(stderr,"error on download cmd: %s\n",
                        linkm_error_msg(err));
                break;
            }
            else { 
                hexdump("scriptline: ", recvbuf, 5);
            }
            pos++;
        }
        
    }
    else if( cmd == CMD_BLINKM_UPLOAD ) {
        
    }
    else if( cmd == CMD_BLINKM_READINPUTS ) {
        cmdbuf[0] = addr;
        cmdbuf[1] = 'i';
        err = linkm_command(dev, LINKM_CMD_I2CTRANS, 2,4, cmdbuf, recvbuf );
        if( err ) {
            fprintf(stderr,"error on readinputs: %s\n", linkm_error_msg(err));
        }
        else { 
            hexdump("inputs: ", recvbuf, 5);
        }
    }

 shutdown:
    linkm_close(dev);
    return 0;
}



