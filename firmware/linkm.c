/*
 * LinkM firmware - USB HID to I2C adapter for BlinkM
 *
 * Command format:  (from host perspective)
 *
 * pos description
 *  0    <startbyte>      ==  0xDA
 *  1    <linkmcmdbyte>   ==  0x01 = i2c transaction, 0x02 = i2c bus scan, etc. 
 *  2    <num_bytes_send> ==  starting at byte 4
 *  3    <num_bytes_recv> ==  may be zero if nothing to send back
 *  4..N <cmdargs>        == command 
 *
 * For most common command, i2c transaction (0x01):
 * pos  description
 *  0   0xDA
 *  1   0x01
 *  2   <num_bytes_to_send>
 *  3   <num_bytes_to_receive>
 *  4   <i2c_addr>   ==  0x00-0x7f
 *  5   <send_byte_0>
 *  6   <send_byte_1>
 *  7   ...
 *
 * Command byte values
 *  0x00 = no command, do not use
 *  0x01 = i2c transact: read + opt. write (N arguments)
 *  0x02 = i2c read                        (N arguments)
 *  0x03 = i2c write                       (N arguments)
 *  0x04 = i2c bus scan                    (2 arguments, start addr, end addr)
 *  0x05 = i2c bus connect/disconnect      (1 argument, connect/disconect)
 *  0x06 = i2c init                        (0 arguments)
 *
 *  0x100 = set status LED                  (1 argument)
 *  0x101 = get status LED
 * 
 * Response / Output buffer format:
 * pos description
 *  0   transaction counter (8-bit, wraps around)
 *  1   response code (0 = okay, other = error)
 *  2   <resp_byte_0>
 *  3   <resp_byte_1>
 *  4   ...
 *
 * 2009, Tod E. Kurt, ThingM, http://thingm.com/
 *
 */

#include <avr/io.h>
#include <avr/wdt.h>        // watchdog
#include <avr/eeprom.h>     //
#include <avr/interrupt.h>  // for sei() 
#include <util/delay.h>     // for _delay_ms() 
#include <string.h>

#include <avr/eeprom.h>
#include <avr/pgmspace.h>   // required by usbdrv.h 
#include "usbdrv.h"
#include "oddebug.h"        // This is also an example for using debug macros 

#include "i2cmaster.h"
#include "uart.h"

#include "linkm-lib.h"

// uncomment to enable debugging to serial port
#define DEBUG   0

#define ENABLE_PLAYTICKER 1

// these aren't used anywhere, just here to note them
#define PIN_LED_STATUS         PORTB4
#define PIN_I2C_ENABLE         PORTB5

#define PIN_I2C_SDA            PORTC4
#define PIN_I2C_SCL            PORTC5

#define PIN_USB_DPLUS          PORTD2
#define PIN_USB_DMINUS         PORTD3

#define LINKM_VERSION_MAJOR    0x13
#define LINKM_VERSION_MINOR    0x37

#if DEUBG > 0
#define printdebug(s)
#else
#define printdebug(s) puts(s)
#endif

/* ------------------------------------------------------------------------- */
/* ----------------------------- USB interface ----------------------------- */
/* ------------------------------------------------------------------------- */

#define REPORT_COUNT 16
/*
PROGMEM char usbHidReportDescriptor[22] = {    // USB report descriptor
    0x06, 0x00, 0xff,              // USAGE_PAGE (Generic Desktop)
    0x09, 0x01,                    // USAGE (Vendor Usage 1)
    0xa1, 0x01,                    // COLLECTION (Application)
    0x15, 0x00,                    //   LOGICAL_MINIMUM (0)
    0x26, 0xff, 0x00,              //   LOGICAL_MAXIMUM (255)
    0x75, 0x08,                    //   REPORT_SIZE (8)
    0x95, REPORT_COUNT,            //   REPORT_COUNT (32)  // was 32
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf)
    0xc0                           // END_COLLECTION
};
*/
PROGMEM char usbHidReportDescriptor[33] = {
    0x06, 0x00, 0xff,              // USAGE_PAGE (Generic Desktop)
    0x09, 0x01,                    // USAGE (Vendor Usage 1)
    0xa1, 0x01,                    // COLLECTION (Application)
    0x15, 0x00,                    //   LOGICAL_MINIMUM (0)
    0x26, 0xff, 0x00,              //   LOGICAL_MAXIMUM (255)
    0x75, 0x08,                    //   REPORT_SIZE (8)

    0x85, 0x01,                    //   REPORT_ID (1)
    0x95, REPORT_COUNT,            //   REPORT_COUNT (was 6)
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf)

    0x85, 0x02,                    //   REPORT_ID (2)
    0x95, 0x83,                    //   REPORT_COUNT (131)
    0x09, 0x00,                    //   USAGE (Undefined)
    0xb2, 0x02, 0x01,              //   FEATURE (Data,Var,Abs,Buf)
    0xc0                           // END_COLLECTION
};

/* Since we define only one feature report, we don't use report-IDs (which
 * would be the first byte of the report). The entire report consists of
 * REPORT_COUNT opaque data bytes.
 */

/* The following variables store the status of the current data transfer */
static uchar    currentAddress;
static uchar    bytesRemaining;

static int numWrites;

static uint8_t msgbuf[REPORT_COUNT];
static uint8_t outmsgbuf[REPORT_COUNT];

static volatile uint16_t tick;         // tick tock clock
static volatile uint16_t timertick;         // tick tock clock

#if DEBUG > 0
// setup serial routines to become stdio
extern int uart_putchar(char c, FILE *stream);
extern int uart_getchar(FILE *stream);
FILE uart_str = FDEV_SETUP_STREAM(uart_putchar, uart_getchar, _FDEV_SETUP_RW);
#endif

typedef struct _params_t {
    uint8_t  playing;      // turn on or off playing
    uint8_t  script_id;    // script id to play
    uint8_t  script_tick;  // number of ticks between script lines
    uint8_t  script_len;   // number of script lines in script
    uint8_t  start_pos;    // start position in the script  FIXME: not impl yet
    uint8_t  fadespeed;    //
    uint8_t  dir;          // play direction FIXME: not impl yet
} params_t;

params_t params;           // local RAM copy of playTicker params
uint16_t script_pos;       // position for playTicker


// magic value read on reset: 0x55 = run bootloader , other = boot normally
#define GOBOOTLOAD_MAGICVAL 0x55
uint8_t bootmode EEMEM = 0; 
params_t ee_params EEMEM = {
    0,   // playing
    0,   // script_id
    0,   // script_tick
    0,   // script_len
    0,   // start_pos
    100, // fadespeed
    0,   // dir
};
//params_t ee_params EEMEM = {
//    1,5,5,2, 0,100,0
//};

int blinkmStop(uint8_t addr );
int blinkmSetRGB(uint8_t addr, uint8_t r, uint8_t g, uint8_t b );
int blinkmSetFadespeed(uint8_t addr, uint8_t fadespeed);
int blinkmPlayScript(uint8_t addr, uint8_t id, uint8_t reps, uint8_t pos);

void(* softReset) (void) = 0;  //declare reset function @ address 0

// ------------------------------------------------------------------------- 
void statusLedToggle(void)
{
    PORTB ^= (1<< PIN_LED_STATUS);  // toggles LED
}
void statusLedSet(int v)
{
    if( v ) PORTB  |=  (1<<PIN_LED_STATUS);
    else    PORTB  &=~ (1<<PIN_LED_STATUS);
}
uint8_t statusLedGet(void)
{
    return (PINB & (1<<PIN_LED_STATUS)) ? 1 : 0;
}

void i2cEnable(int v) {
    if( v ) PORTB  |=  (1<<PIN_I2C_ENABLE);
    else    PORTB  &=~ (1<<PIN_I2C_ENABLE);
}

// 
// Called from usbFunctionWrite() when we've received the entire USB message
// 
void handleMessage(void)
{
    outmsgbuf[0]++;                   // say we've handled a msg
    outmsgbuf[1] = LINKM_ERR_NONE;    // be optimistic
    // outmsgbuf[2] starts the actual received data

    uint8_t* mbufp = msgbuf;  // was +1 because had forgot to send repotid

    if( mbufp[0] != START_BYTE  ) {   // byte 0: start marker
        outmsgbuf[1] = LINKM_ERR_BADSTART;
        return;
    }
    
    uint8_t cmd      = mbufp[1];      // byte 1: command
    uint8_t num_sent = mbufp[2];      // byte 2: number of bytes sent
    uint8_t num_recv = mbufp[3];      // byte 3: number of bytes to return back

#if DEBUG > 0
    printf("cmd:%d, sent:%d, recv:%d\n",cmd,num_sent,num_recv);
#endif

    // i2c transaction
    // params:
    //   mpbufp[4] == i2c addr
    //   mpbufp[5..5+numsend] == data to write
    // returns:
    //   outmsgbuf[0] == transaction counter 
    //   outmsgbuf[1] == response code
    //   outmsgbuf[2] == i2c response byte 0  (if any)
    //   outmsgbuf[3] == i2c response byte 1  (if any)
    // ...
    // FIXME: because "num_sent" and "num_recv" are outside this command
    //        it's confusing
    if( cmd == LINKM_CMD_I2CTRANS ) {
        uint8_t addr      = mbufp[4];  // byte 4: i2c addr or command

        printdebug("A.");
        if( addr >= 0x80 ) {   // invalid valid I2C address
            outmsgbuf[1] = LINKM_ERR_BADARGS;
            return;
        }

        printdebug("B.");
        if( i2c_start( (addr<<1) | I2C_WRITE ) == 1) {  // start i2c trans
            printdebug("!");
            outmsgbuf[1] = LINKM_ERR_I2C;
            i2c_stop();
            return;
        }
        printdebug("C.");
        // start succeeded, so send data
        for( uint8_t i=0; i<num_sent-1; i++) {
            i2c_write( mbufp[5+i] );   // byte 5-N: i2c command to send
        }

        printdebug("D.");
        if( num_recv != 0 ) {
            statusLedSet(1);
            if( i2c_rep_start( (addr<<1) | I2C_READ ) == 1 ) { // start i2c
                outmsgbuf[1] = LINKM_ERR_I2CREAD;
            }
            else {
                for( uint8_t i=0; i<num_recv; i++) {
                    //uint8_t c = i2c_read( (i!=(num_recv-1)) );//read from i2c
                    int c = i2c_read( (i!=(num_recv-1)) ); // read from i2c
                    if( c == -1 ) {  // timeout, get outx
                        outmsgbuf[1] = LINKM_ERR_I2CREAD;
                        break;
                    }
                    outmsgbuf[2+i] = c;             // store in response buff
                }
            }
            statusLedSet(0);
        }
        printdebug("Z.\n");
        i2c_stop();  // done!
    }
    // i2c write
    // params:
    //   mbufp[4]     == i2c addr
    //   mbufp[5]     == read after write boolean (1 == read, 0 = no read)
    // returns:
    //   outmsgbuf[0] == transaction counter 
    //   outmsgbuf[1] == response code
    // FIXME: this function doesn't work i think
    else if( cmd == LINKM_CMD_I2CWRITE ) {
        uint8_t addr      = mbufp[4];  // byte 4: i2c addr or command
        uint8_t doread    = mbufp[5];  // byte 5: do read or not after this

        if( addr >= 0x80 ) {   // invalid valid I2C address
            outmsgbuf[1] = LINKM_ERR_BADARGS;
            return;
        }

        if( i2c_start( (addr<<1) | I2C_WRITE ) == 1) {  // start i2c trans
            outmsgbuf[1] = LINKM_ERR_I2C;
            i2c_stop();
            return;
        }
        // start succeeded, so send data
        for( uint8_t i=0; i<num_sent-1; i++) {
            i2c_write( mbufp[5+i] );   // byte 5-N: i2c command to send
        } 
        if( !doread ) {
            i2c_stop();   // done!
        }
    }
    // i2c read
    // params:
    //   mpbuf[4]     == i2c addr 
    // returns:
    //   outmsgbuf[0] == transaction counter 
    //   outmsgbuf[1] == response code
    //   outmsgbuf[2] == i2c response byte 0  (if any)
    //   outmsgbuf[3] == i2c response byte 1  (if any)
    // ...
    else if( cmd == LINKM_CMD_I2CREAD ) {
        uint8_t addr      = mbufp[4];  // byte 4: i2c addr 

        if( num_recv == 0 ) {
            outmsgbuf[1] = LINKM_ERR_BADARGS;
            return;
        }
        statusLedSet(1);

        if( i2c_rep_start( (addr<<1) | I2C_READ ) == 1 ) { // start i2c
            outmsgbuf[1] = LINKM_ERR_I2CREAD;
        }
        else {
            for( uint8_t i=0; i<num_recv; i++) {
                uint8_t c = i2c_read( (i!=(num_recv-1)) ); // read from i2c
                outmsgbuf[2+i] = c;             // store in response buff
            }
        }
        statusLedSet(0);
        i2c_stop();
    }
    // i2c bus scan
    // params:
    //   mbufp[4]     == start addr
    //   mbufp[5]     == end addr
    // returns:
    //   outmsgbuf[0] == transaction counter
    //   outmsgbuf[1] == response code
    //   outmsgbuf[2] == number of devices found
    //   outmsgbuf[3] == addr of 1st device
    //   outmsgbuf[4] == addr of 2nd device
    // ...
    else if( cmd == LINKM_CMD_I2CSCAN ) {
        uint8_t addr_start = mbufp[4];  // byte 4: start addr of scan
        uint8_t addr_end   = mbufp[5];  // byte 5: end addr of scan
        if( addr_start >= 0x80 || addr_end >= 0x80 || addr_start > addr_end ) {
            outmsgbuf[1] = LINKM_ERR_BADARGS;
            return;
        }
        int numfound = 0;
        for( uint8_t a = 0; a < (addr_end-addr_start); a++ ) {
            if( i2c_start( ((addr_start+a)<<1)|I2C_WRITE)==0 ) { // dev found
                outmsgbuf[3+numfound] = addr_start+a;  // save the address 
                numfound++;
            }
            i2c_stop();
        }
        outmsgbuf[2] = numfound;
    }
    // i2c bus connect/disconnect
    // params:
    //   mpbuf[4]  == connect (1) or disconnect (0)
    // returns:
    //   outmsgbuf[0] == transaction counter
    //   outmsgbuf[1] == response code
    else if( cmd == LINKM_CMD_I2CCONN  ) {
        uint8_t conn = mbufp[4];        // byte 4: connect/disconnect boolean
        i2cEnable( conn );
    }
    // i2c init
    // params:
    //   none
    // returns:
    //   outmsgbuf[0] == transaction counter
    //   outmsgbuf[1] == response code
    else if( cmd == LINKM_CMD_I2CINIT ) {  // FIXME: what's the real soln here?
        i2c_stop();
        _delay_ms(1);
        i2c_init();
    }
    // set status led state
    // params:
    //   mbufp[4]  == on (1) or off (0)
    // returns:
    //   outmsgbuf[0] == transaction counter
    //   outmsgbuf[1] == response code
    else if( cmd == LINKM_CMD_STATLEDSET ) {
        uint8_t led = mbufp[4];        // byte 4: on/off boolean
        statusLedSet( led );
    }
    // get status led state
    // params:
    //   none
    // returns:
    //   outmsgbuf[0] == transaction counter
    //   outmsgbuf[1] == response code
    //   outmsgbuf[2] == state of status LED
    else if( cmd == LINKM_CMD_STATLEDGET ) {
        // no arguments, just a single return byte
        outmsgbuf[2] = statusLedGet();
    }
    // set play statemachine params
    // params:
    //   mbufp[4] == playing on/off
    //   mbufp[5] == script_id
    //   mbufp[6] == ticks between steps
    //   mbufp[7] == length of script   and so on
    // returns:
    //  none
    else if( cmd == LINKM_CMD_PLAYSET ) { 
        memcpy( &params, mbufp+4, sizeof(params_t));
        script_pos = params.start_pos;
        if( params.fadespeed != 0 ) {
            blinkmSetFadespeed(0, params.fadespeed);            
        }
    }
    // get player statemachine params
    // params:
    //   none
    // returns:
    //   outmsgbuf[0] == transaction counter
    //   outmsgbuf[1] == response code
    //   outmsgbuf[2] == playing 
    //   outmsgbuf[3] == script_id
    //   outmsgbuf[4] == script_tick 
    //   outmsgbuf[5] == script_len  nad so on
    else if( cmd == LINKM_CMD_PLAYGET ) { 
        memcpy( outmsgbuf+2, &params, sizeof(params_t));
    }
    // trigger LinkM to save current params to EEPROM
    // params:
    //   none
    // returns:
    //   none
    else if( cmd == LINKM_CMD_EESAVE ) {
        statusLedToggle();
        eeprom_write_block( &params, &ee_params, sizeof(params_t) ); 
    }
    // trigger LinkM to load its saved EEPROM params into RAM
    // params:
    //   none
    // returns:
    //   none
    else if( cmd == LINKM_CMD_EELOAD ) {
        statusLedToggle();
        eeprom_read_block( &params, &ee_params, sizeof(params_t) );
    }
    // get linkm version
    // params:
    //   none
    // returns:
    //   outmsgbuf[0] == transaction counter
    //   outmsgbuf[1] == response code
    //   outmsgbuf[2] == major linkm version
    //   outmsgbuf[3] == minor linkm version
    else if( cmd == LINKM_CMD_VERSIONGET ) {
        outmsgbuf[2] = LINKM_VERSION_MAJOR;
        outmsgbuf[3] = LINKM_VERSION_MINOR;
    }
    // reset into bootloader
    else if( cmd == LINKM_CMD_GOBOOTLOAD ) { 
        statusLedToggle();
        eeprom_write_byte( &bootmode, GOBOOTLOAD_MAGICVAL );
    }
    // cmd xxxx == 
}

/* usbFunctionRead() is called when the host requests a chunk of data from
 * the device. For more information see the docs in usbdrv/usbdrv.h.
 */
uchar   usbFunctionRead(uchar *data, uchar len)
{
    if(len > bytesRemaining)
        len = bytesRemaining;
    
    memcpy( data, outmsgbuf + currentAddress, len);
    numWrites = 0;
    currentAddress += len;
    bytesRemaining -= len;
    return len;
}

/* usbFunctionWrite() is called when the host sends a chunk of data to the
 * device. For more information see the documentation in usbdrv/usbdrv.h.
 */
uchar   usbFunctionWrite(uchar *data, uchar len)
{
    if(bytesRemaining == 0)
        return 1;               // end of transfer 
    if(len > bytesRemaining)
        len = bytesRemaining;
    
    memcpy( msgbuf+currentAddress, data, len );
    currentAddress += len;
    bytesRemaining -= len;
    
    if( bytesRemaining == 0 )  {   // got it all
        handleMessage();
    }
    
    return bytesRemaining == 0; // return 1 if this was the last chunk 
}

// ------------------------------------------------------------------------- 
/**
 *
 */
usbMsgLen_t usbFunctionSetup(uchar data[8])
{
    usbRequest_t    *rq = (void *)data;
    
    // HID class request 
    if((rq->bmRequestType & USBRQ_TYPE_MASK) == USBRQ_TYPE_CLASS) {
        // wValue: ReportType (highbyte), ReportID (lowbyte) 
        if(rq->bRequest == USBRQ_HID_GET_REPORT){  
            // since we have only one report type, we can ignore the report-ID 
            bytesRemaining = REPORT_COUNT;
            currentAddress = 0;
            return USB_NO_MSG;  // use usbFunctionRead() to obtain data 
        }
        else if(rq->bRequest == USBRQ_HID_SET_REPORT) {
            // since we have only one report type, we can ignore the report-ID 
            bytesRemaining = REPORT_COUNT;
            currentAddress = 0;
            return USB_NO_MSG; // use usbFunctionWrite() to recv data from host 
        }
    } else {
        // ignore vendor type requests, we don't use any 
    }
    return 0;
}

// -------------------------------------------------------------------------

// 
int blinkmStop(uint8_t addr ) 
{
    if( i2c_start( (addr<<1) | I2C_WRITE ) == 1) {  // start i2c transaction
        i2c_stop();
        return 1;
    }
    i2c_write( 'o' );
    i2c_stop();   // done!
    return 0;
}

//
int blinkmSetRGB(uint8_t addr, uint8_t r, uint8_t g, uint8_t b )
{
    if( i2c_start( (addr<<1) | I2C_WRITE ) == 1) {  // start i2c transaction
        i2c_stop();
        return 1;
    }
    i2c_write( 'n' );  // turn off now
    i2c_write( r );
    i2c_write( g );
    i2c_write( b );
    i2c_stop();   // done!
    return 0;
}

//
int blinkmSetFadespeed(uint8_t addr, uint8_t fadespeed)
{
    if( i2c_start( (addr<<1) | I2C_WRITE ) == 1) {  // start i2c transaction
        i2c_stop();
        return 1;
    }
    i2c_write( 'f' );
    i2c_write( fadespeed );
    i2c_stop();   // done!
    return 0;
}

//
// Send I2C play script command to blinkm
// returns zero on success, non-zero on fail
//
int blinkmPlayScript(uint8_t addr, uint8_t id, uint8_t reps, uint8_t pos)
{
    if( i2c_start( (addr<<1) | I2C_WRITE ) == 1) {  // start i2c transaction
        i2c_stop();
        return 1;
    }
    i2c_write( 'p' );
    i2c_write( id );  
    i2c_write( reps );
    i2c_write( pos );
    i2c_stop();   // done!
    return 0;
}

//
// Stand-alone play state machine
// Drives BlinkMs to play back their scripts in sync
//
void playTicker(void)
{
    if( !params.playing ) return;
    if( tick >= params.script_tick ) {
        //printf("tick!");
        tick = 0;
        blinkmPlayScript( 0, params.script_id, 0, script_pos );
        statusLedToggle();
        script_pos++;
        if( script_pos == params.script_len ) {  // loop
            script_pos = 0;
        }
    }
}

//
// called periodically as a timer
// should update 'tick' at 30.517 Hz
//
ISR(TIMER1_OVF_vect)
{
    timertick++; 
    if( timertick == 6 ) {
        timertick = 0;
        tick++;
    }
}

// ------------------------------------------------------------------------- 

int main(void)
{
    uchar   i,j;
    
    wdt_enable(WDTO_1S);
    // Even if you don't use the watchdog, turn it off here. On newer devices,
    // the status of the watchdog (on/off, period) is PRESERVED OVER RESET!
    //DBG1(0x00, 0, 0);       // debug output: main starts
    // RESET status: all port bits are inputs without pull-up.
    // That's the way we need D+ and D-. Therefore we don't need any
    // additional hardware initialization. (for USB)
    
    // make pins outputs 
    DDRB |= (1<< PIN_LED_STATUS) | (1<< PIN_I2C_ENABLE); 
    // enable pullups on SDA & SCL
    PORTC |= _BV(PIN_I2C_SDA) | _BV(PIN_I2C_SCL);

    statusLedSet( 0 );      // turn off LED to start

    i2c_init();             // init I2C interface
    i2cEnable(1);           // enable i2c buffer chip

    for( j=0; j<4; j++ ) {
        statusLedToggle();  // then toggle LED
        wdt_reset();
        for( i=0; i<2; i++) { // wait for power to stabilize & blink status
            _delay_ms(10);
        }
    }

    // load params from EEPROM
    eeprom_read_block( &params, &ee_params, sizeof(params_t) );
    blinkmStop( 0 );         // stop all scripts  FIXME: maybe make this a param?
    blinkmSetRGB(0, 0,0,0 ); // turn all off
    if( params.fadespeed != 0 ) {
        blinkmSetFadespeed(0, params.fadespeed);            
    }

#if DEBUG > 0
    uart_init();                // initialize UART hardware
    stdout = stdin = &uart_str; // setup stdio = RS232 port
    puts("linkm dongle test");
#endif

    // debug: insert some known data into the outbuffer
    /*
    outmsgbuf[8]  = 0xde;
    outmsgbuf[9]  = 0xad;
    outmsgbuf[10] = 0xbe;
    outmsgbuf[11] = 0xef;
    for( int i=0; i<4; i++ ) {
        outmsgbuf[12+i] = 0x60 + i;
    }
    */
    
    //odDebugInit();
    usbInit();
    usbDeviceDisconnect();  
    // enforce re-enumeration, do this while interrupts are disabled!
    i = 0;
    while(--i){             // fake USB disconnect for > 250 ms 
        wdt_reset();
        _delay_ms(1);
    }
    usbDeviceConnect();

#if ENABLE_PLAYTICKER == 1
    // set up periodic timer for state machine
    TCCR1B |= _BV( CS10 );         // 12e6/1/65536 == 183.1  then, / 6 = 30.517
    TIFR1  |= _BV( TOV1 );         // clear interrupt flag
    TIMSK1 |= _BV( TOIE1 );        // enable overflow interrupt
#endif

    sei();
    
    //DBG1(0x01, 0, 0);       // debug output: main loop starts 
    for(;;){                // main event loop 
        //DBG1(0x02, 0, 0);     // debug output: main loop iterates 
        wdt_reset();
        usbPoll();
#if ENABLE_PLAYTICKER == 1
        playTicker();
#endif
    }
    return 0;
}


// ------------------------------------------------------------------------- 

/**
 * Originally from:
 * Name: main.c
 * Project: hid-data, example how to use HID for data transfer
 * Author: Christian Starkjohann
 * Creation Date: 2008-04-11
 * Tabsize: 4
 * Copyright: (c) 2008 by OBJECTIVE DEVELOPMENT Software GmbH
 * License: GNU GPL v2 (see License.txt), GNU GPL v3 or proprietary (CommercialLicense.txt)
 * This Revision: $Id: main.c 692 2008-11-07 15:07:40Z cs $
 */

/*
This example should run on most AVRs with only little changes. No special
hardware resources except INT0 are used. You may have to change usbconfig.h for
different I/O pins for USB. Please note that USB D+ must be the INT0 pin, or
at least be connected to INT0 as well.
*/
