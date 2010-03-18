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
#include <sys/time.h>

#include "linkm-lib.h"

#include "linkmbootload-lib.h"

static int debug = 0;

// local states for the "cmd" option variable
// yes, this has a lot of duplication with the enum in linkm-lib.h
enum { 
    CMD_NONE = 0,
    CMD_LINKM_VERSIONGET,
    CMD_LINKM_EESAVE,
    CMD_LINKM_EELOAD,
    CMD_LINKM_READ,
    CMD_LINKM_WRITE,
    CMD_LINKM_CMD,
    CMD_LINKM_STATLEDSET,
    CMD_LINKM_I2CSCAN,
    CMD_LINKM_I2CENABLE,
    CMD_LINKM_I2CINIT,
    CMD_LINKM_PLAYSET,
    CMD_LINKM_PLAYGET,
    CMD_LINKM_BOOTLOADGO,
    CMD_LINKM_BOOTLOADRESET,
    CMD_LINKM_BOOTLOAD,
    CMD_BLINKM_CMD,
    CMD_BLINKM_OFF,
    CMD_BLINKM_ON,
    CMD_BLINKM_PLAY,
    CMD_BLINKM_STOP,
    CMD_BLINKM_FADESPEED,
    CMD_BLINKM_COLOR,
    CMD_BLINKM_UPLOAD,
    CMD_BLINKM_DOWNLOAD,
    CMD_BLINKM_READINPUTS,
    CMD_BLINKM_SETADDR,
    CMD_BLINKM_GETVERSION,
    CMD_BLINKM_RANDOM,
};

uint32_t stampstart();
uint32_t stampstop(uint32_t start);

// ------------------------------------------------------------------------- 

void usage(char *myName)
{
    printf(
"Usage: \n"
"  %s <cmd> [options]\n"
"where <cmd> is one of:\n"
"  --cmd <blinkmcmd>  Send a blinkm command  \n"
"  --off              Stop script & turn off blinkm at address (or all) \n"
"  --on               Play startup script at address (or all) \n"
"  --play <n>         Play light script N \n"
"  --stop             Stop playing light script \n"
"  --color 'rr,gg,bb' Fade to color rr,gg,bb\n"
"  --fadespeed <n>    Set BlinkM fadespeed\n"
"  --getversion       Gets BlinkM version \n"
"  --setaddr <newa>   Set address of blinkm at address 'addr' to 'newa' \n"
"  --random <n>       Send N random colors to blinkm\n"
"  --i2cscan          Scan I2c bus for devices  \n"
"  --i2enable <0|1>   Enable or disable the I2C bus (for connecting devices) \n"
"  --upload           Upload a light script to blinkm (reqs addr & file) \n"
"  --download <n>     Download light script n from blinkm (reqs addr & file) \n"
"  --readinputs       Read inputs (on MaxM)\n"
"  --linkmcmd         Send a raw linkm command  \n"
"  --linkmversion     Get LinkM version \n"
"  --linkmeesave      Save playerset and other parms for later \n"
"  --linkmeeload      Load playerset and other parms \n"
"  --playset <onoff,scriptid,len,tickspeed>  set periodic play ticker params \n"
"  --statled <0|1>    Turn on or off status LED  \n"
"  --bootloadgo       Start LinkMBoot bootloaer mode\n"
"\n"
"and [options] are:\n"
"  -h, --help                   Print this help message\n"
"  -a addr, --addr=i2caddr      I2C address for command (default 0)\n"
"  -f file, --afile=file        Read or save to this file\n"
"  -m ms,   --miilis=millis     Set millisecs betwen actions (default 100)\n"
"  -v, --verbose                verbose debugging msgs\n"
"\n"
"Examples:\n"
"  linkm-tool --off                            # stop & turn off all blinkms\n"
"  linkm-tool --color '0xff,0xff,0x00'         # fade to yellow \n"
"  linkm-tool -a 9 --cmd \"'c',0xff,0x00,0xff\"  # fade to purple \n"
"  linkm-tool -a 9 --download 5                # download script #5\n" 
"  linkm-tool --playset \"1,0,4,48\"   # set linkm to play script0,spd4,len48\n"
"  linkm-tool --playset \"1,0,4,48,0,20,0\" # with pos0,fade20,dir0\n"
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
    int16_t arg  = 0;
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
        {"linkmversion",no_argument,      &cmd,   CMD_LINKM_VERSIONGET },
        {"linkmeesave",no_argument,       &cmd,   CMD_LINKM_EESAVE },
        {"linkmeeload",no_argument,       &cmd,   CMD_LINKM_EELOAD },
        {"statled",    required_argument, &cmd,   CMD_LINKM_STATLEDSET },
        {"i2cscan",    no_argument,       &cmd,   CMD_LINKM_I2CSCAN },
        {"i2cenable",  required_argument, &cmd,   CMD_LINKM_I2CENABLE },
        {"i2cinit",    no_argument,       &cmd,   CMD_LINKM_I2CINIT },
        {"cmd",        required_argument, &cmd,   CMD_BLINKM_CMD },
        {"off",        no_argument,       &cmd,   CMD_BLINKM_OFF },
        {"on",         no_argument,       &cmd,   CMD_BLINKM_ON },
        {"stop",       no_argument,       &cmd,   CMD_BLINKM_STOP },
        {"play",       required_argument, &cmd,   CMD_BLINKM_PLAY },
        {"fadespeed",  required_argument, &cmd,   CMD_BLINKM_FADESPEED },
        {"color",      required_argument, &cmd,   CMD_BLINKM_COLOR },
        {"upload",     required_argument, &cmd,   CMD_BLINKM_UPLOAD },
        {"download",   required_argument, &cmd,   CMD_BLINKM_DOWNLOAD },
        {"readinputs", no_argument,       &cmd,   CMD_BLINKM_READINPUTS },
        {"random",     required_argument, &cmd,   CMD_BLINKM_RANDOM },
        {"setaddr",    required_argument, &cmd,   CMD_BLINKM_SETADDR },
        {"getversion", no_argument,       &cmd,   CMD_BLINKM_GETVERSION },
        {"playset",    required_argument, &cmd,   CMD_LINKM_PLAYSET },
        {"playget",    no_argument,       &cmd,   CMD_LINKM_PLAYGET },
        {"bootloadgo",   no_argument,       &cmd,   CMD_LINKM_BOOTLOADGO },
        {"bootloadreset",no_argument,       &cmd,   CMD_LINKM_BOOTLOADRESET },
        {"bootload",     required_argument, &cmd,   CMD_LINKM_BOOTLOAD },
        {NULL,         0,                 0,      0}
    };

    while(1) {
        opt = getopt_long (argc, argv, opt_str, loptions, &option_index);
        if (opt==-1) break; // parsed all the args
        switch (opt) {
        case 0:             // deal with long opts that have no short opts
            switch(cmd) { 
            case CMD_LINKM_PLAYSET:
            case CMD_LINKM_WRITE:
            case CMD_LINKM_CMD:
            case CMD_BLINKM_CMD:
            case CMD_BLINKM_COLOR:
                hexread(cmdbuf, optarg, sizeof(cmdbuf));  // cmd w/ hexlist arg
                break;
            case CMD_LINKM_STATLEDSET:
            case CMD_LINKM_I2CENABLE:
            case CMD_BLINKM_RANDOM:
            case CMD_BLINKM_SETADDR:
            case CMD_BLINKM_PLAY:
            case CMD_BLINKM_FADESPEED:
                arg = strtol(optarg,NULL,0);   // cmd w/ number arg
                break;
            case CMD_LINKM_BOOTLOAD:
                strcpy(file,optarg);
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


    if( cmd == CMD_LINKM_BOOTLOAD ) {
        printf("linkmboot uploading firmware: %s\n",file);
        int rc = uploadFromFile(file, 0);
        if( rc == -1 ) {
            return 1;
        }
        if( rc == -2 ) {
            fprintf(stderr, "No data in input file, exiting.\n");
            return 0;
        }
        else if( rc == -3 ) { 
            fprintf(stderr,"error uploading\n");
        }
        printf("Flashing done.\n");
        return 1;
    }

    if( cmd == CMD_LINKM_BOOTLOADRESET ) {
        printf("linkmboot resetting bootloader:\n");
        if( resetLinkMBoot() ) {
            exit(1);
        }
        printf("reset done\n");
        exit(0);
    }
    
    // open up linkm, get back a 'dev' to pass around
    if( (err = linkm_open( &dev )) ) {
        fprintf(stderr, "Error opening LinkM: %s\n", linkm_error_msg(err));
        exit(1);
    }
    
    if( cmd == CMD_LINKM_BOOTLOADGO ) {
        printf("linkm switching to bootloader:\n");
        err = linkm_command(dev, LINKM_CMD_GOBOOTLOAD, 0, 0, NULL, NULL);
        //if( err ) {
        //    fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        //}
        printf("linkm is now in bootloader mode\n");
    }
    else if( cmd == CMD_LINKM_VERSIONGET ) {
        printf("linkm version: ");
        err = linkm_command(dev, LINKM_CMD_VERSIONGET, 0, 2, NULL, recvbuf);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
        else {  // success
            hexdump("", recvbuf, 2);
        }
    }
    else if( cmd == CMD_LINKM_PLAYSET ) {   // control LinkM's state machine
        printf("linkm play set: ");
        err = linkm_command(dev, LINKM_CMD_PLAYSET, 7,0, cmdbuf, NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
        printf("done");
    }
    else if( cmd == CMD_LINKM_PLAYGET ) {   // read LinkM's state machine
        printf("linkm play get: ");
        err = linkm_command(dev, LINKM_CMD_PLAYGET, 0,7, NULL, recvbuf);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
        else {  // success
            hexdump("", recvbuf, 7);
        }
    }
    else if( cmd == CMD_LINKM_EESAVE ) {   // tell linkm to save params to eeprom
        printf("linkm eeprom  save:\n");
        err = linkm_command(dev, LINKM_CMD_EESAVE, 0,0, NULL, NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_EELOAD ) {  // tell linkm to load params to eeprom
        printf("linkm eeprom load:\n");
        err = linkm_command(dev, LINKM_CMD_EELOAD, 0,0, NULL, NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_STATLEDSET ) {    // control LinkM's status LED 
        err = linkm_command(dev, LINKM_CMD_STATLEDSET, 1,0,(uint8_t*)&arg,NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_I2CENABLE ) {    // enable/disable i2c buffer
        err = linkm_command(dev, LINKM_CMD_I2CCONN, 1,0,  (uint8_t*)&arg,NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_I2CINIT ) {     // restart LinkM's I2C software
        err = linkm_command(dev, LINKM_CMD_I2CINIT, 0,0,  NULL,NULL);
        if( err ) {
            fprintf(stderr,"error on linkm cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_LINKM_I2CSCAN ) { 
        //if( addr == 0 ) addr = 1;
        printf("i2c scan from addresses %d - %d\n", 1, 113);
        int saddr = addr;
        for( int i=0; i < 7; i++ ) { 
            saddr = i*16 + 1;
            cmdbuf[0] = saddr;    // start address: 01
            cmdbuf[1] = saddr+16; // end address:   16 // FIXME: allow arbitrary
            err = linkm_command(dev, LINKM_CMD_I2CSCAN, 2, 16, cmdbuf, recvbuf);
            if( err ) {
                fprintf(stderr,"error on i2c scan: %s\n",linkm_error_msg(err));
            }
            else {
                if(debug) hexdump("recvbuf:", recvbuf, 16);
                int cnt = recvbuf[0];
                if( cnt != 0 ) {
                    for( int i=0; i< cnt; i++ ) {
                        printf("device found at address %d\n",recvbuf[1+i]);
                    }
                }
            }
        } // for
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
        if( addr == 0 ) {
            printf("Must specify non-zero address for download\n");
            goto shutdown;
        }
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
    else if( cmd == CMD_BLINKM_COLOR ) {
        uint8_t r = cmdbuf[0];     // this is kind of dumb
        uint8_t g = cmdbuf[1];
        uint8_t b = cmdbuf[2];
        printf("addr %d: fading to color 0x%02x,0x%02x,0x%02x\n",addr,r,g,b);
        cmdbuf[0] = addr;
        cmdbuf[1] = 'c';
        cmdbuf[2] = r;
        cmdbuf[3] = g;
        cmdbuf[4] = b;
        err = linkm_command(dev, LINKM_CMD_I2CTRANS, 5,0, cmdbuf, NULL );
        if( err ) {
            fprintf(stderr,"error on color cmd: %s\n",linkm_error_msg(err));
        }
    }
    else if( cmd == CMD_BLINKM_RANDOM  ) {
        printf("addr %d: %d random every %d millis\n", addr,arg,millis);
        uint32_t start = stampstart();
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
        stampstop(start);
    }
    else if( cmd == CMD_BLINKM_PLAY  ) {
        printf("addr %d: playing script #%d\n", addr,arg);
        cmdbuf[0] = addr; 
        cmdbuf[1] = 'p';  // play script
        cmdbuf[2] = arg;
        cmdbuf[3] = 0;
        cmdbuf[4] = 0;
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 5,0, cmdbuf, NULL))) 
            fprintf(stderr,"error on play: %s\n",linkm_error_msg(err));
    }
    else if( cmd == CMD_BLINKM_STOP  ) {
        printf("addr %d: stopping script\n", addr);
        cmdbuf[0] = addr; 
        cmdbuf[1] = 'o';  // stop script
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 2,0, cmdbuf, NULL))) 
            fprintf(stderr,"error on stop: %s\n",linkm_error_msg(err));
    }
    else if( cmd == CMD_BLINKM_OFF  ) {
        printf("addr %d: turning off\n", addr);
        cmdbuf[0] = addr; 
        cmdbuf[1] = 'o';  // stop script
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 2,0, cmdbuf, NULL))) 
            fprintf(stderr,"error on blinkmoff cmd: %s\n",linkm_error_msg(err));
        cmdbuf[1] = 'n';  // set rgb color now now
        cmdbuf[2] = cmdbuf[3] = cmdbuf[4] = 0x00;   // to zeros
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 5,0, cmdbuf, NULL))) 
            fprintf(stderr,"error on blinkmoff cmd: %s\n",linkm_error_msg(err));
    }
    else if( cmd == CMD_BLINKM_ON  ) {
        printf("addr %d: turning on\n", addr);
        cmdbuf[0] = addr; 
        cmdbuf[1] = 'p';  // play script
        cmdbuf[2] = 0;
        cmdbuf[3] = 0;
        cmdbuf[4] = 0;
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 5,0, cmdbuf, NULL))) 
            fprintf(stderr,"error on play: %s\n",linkm_error_msg(err));
    }
    else if( cmd == CMD_BLINKM_FADESPEED  ) {
        printf("addr %d: setting fadespeed to %d\n", addr,arg);
        cmdbuf[0] = addr; 
        cmdbuf[1] = 'f';  // set fadespeed
        cmdbuf[2] = arg;
        if( (err = linkm_command(dev, LINKM_CMD_I2CTRANS, 3,0, cmdbuf, NULL))) 
            fprintf(stderr,"error on play: %s\n",linkm_error_msg(err));
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
            err = linkm_command(dev, LINKM_CMD_I2CTRANS, 4,5, cmdbuf,recvbuf );
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
        printf("unsupported right now\n");
    }
    else if( cmd == CMD_BLINKM_READINPUTS ) {
        if( addr == 0 ) {
            printf("Must specify non-zero address for readinputs\n");
            goto shutdown;
        }
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
    // low-level linkm cmd
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
    // low-level read
    else if( cmd == CMD_LINKM_READ ) {  // low-level read linkm buffer
        printf("linkm read:\n");
        memset( buffer, 0, sizeof(buffer));
        len = sizeof(buffer);
        if((err = usbhidGetReport(dev, 0, (char*)buffer, &len)) != 0) {
            fprintf(stderr, "error reading data: %s\n", linkm_error_msg(err));
        } else {
            hexdump("", buffer + 1, sizeof(buffer) - 1);
        }
    } // low-level write
    else if( cmd == CMD_LINKM_WRITE ) {  // low-level write linkm buffer
        printf("linkm write:\n");
        memset( buffer, 0, sizeof(buffer));
        memcpy( buffer+1, cmdbuf, sizeof(cmdbuf) );
        if(debug) hexdump("linkm write: ", buffer, 16); // print first bytes 
        if((err = usbhidSetReport(dev, (char*)buffer, sizeof(buffer))) != 0) {
            fprintf(stderr, "error writing data: %s\n", linkm_error_msg(err));
        }
    }

 shutdown:
    linkm_close(dev);
    return 0;
}

// ------------------------------------------------------------------------

uint32_t stampstart()
{
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;
	uint32_t         start;
    
	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);
 
	printf("TIMESTAMP-START\t  %d:%02d:%02d:%ld (~%ld ms)\n", tm->tm_hour,
	       tm->tm_min, tm->tm_sec, (long)tv.tv_usec,
	       (long)(tm->tm_hour * 3600 * 1000 + tm->tm_min * 60 * 1000 +
                  tm->tm_sec * 1000 + tv.tv_usec / 1000));
    
	start = tm->tm_hour * 3600 * 1000 + tm->tm_min * 60 * 1000 +
		tm->tm_sec * 1000 + tv.tv_usec / 1000;
    
	return (start);
}
 
uint32_t stampstop(uint32_t start)
{
	struct timeval  tv;
	struct timezone tz;
	struct tm      *tm;
	uint32_t         stop;
 
	gettimeofday(&tv, &tz);
	tm = localtime(&tv.tv_sec);
 
	stop = tm->tm_hour * 3600 * 1000 + tm->tm_min * 60 * 1000 +
		tm->tm_sec * 1000 + tv.tv_usec / 1000;
 
	printf("TIMESTAMP-END\t  %d:%02d:%02d:%ld (~%ld ms) \n", tm->tm_hour,
	       tm->tm_min, tm->tm_sec, (long)tv.tv_usec,
	       (long)(tm->tm_hour * 3600 * 1000 + tm->tm_min * 60 * 1000 +
                  tm->tm_sec * 1000 + tv.tv_usec / 1000));
 
	printf("ELAPSED\t  %d ms\n", stop - start);
 
	return (stop);
}


