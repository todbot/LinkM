/**
 *
 */


#include "linkmbootload-lib.h"
#include "usbcalls.h"


int  parseUntilColon(FILE *fp);
int  parseHex(FILE *fp, int numDigits);
int  parseIntelHex(const char *hexfile, char buffer[65536 + 256], int *startAddr, int *endAddr);
char *usbErrorMessage(int errCode);
int  getUsbInt(char *buffer, int numBytes);
void setUsbInt(char *buffer, int value, int numBytes);


/* ------------------------------------------------------------------------- */

typedef struct deviceInfo{
    char    reportId;
    char    pageSize[2];
    char    flashSize[4];
}deviceInfo_t;

typedef struct deviceData{
    char    reportId;
    char    address[3];
    char    data[128];
}deviceData_t;

union{
    char            bytes[1];
    deviceInfo_t    info;
    deviceData_t    data;
} buffer;

/* ------------------------------------------------------------------------- */

/*
 *
 */
int linkmboot_findLinkM(void)
{
   usbDevice_t *dev = NULL;
   int         rc = 0;  // 100 == LinkM, 101 == LinkMBoot  FIXME:  make typdef

    // look for LinkM
   if((rc = usbOpenDevice(&dev, 
                          IDENT_VENDOR_NUM, IDENT_VENDOR_STRING, 
                          IDENT_PRODUCT_NUM, IDENT_PRODUCT_STRING, 1)) != 0){

       // look for LinkMBoot
       if((rc = usbOpenDevice(&dev, IDENT_BOOT_VENDOR_NUM, IDENT_BOOT_VENDOR_STRING, IDENT_BOOT_PRODUCT_NUM, IDENT_BOOT_PRODUCT_STRING,1)) != 0){
        fprintf(stderr, "Error opening LinkM: %s\n", usbErrorMessage(rc));
       }
       else { 
           rc = FOUND_LINKMBOOT;  // found LinkMBoot   
       }
   }
   else { 
       rc = FOUND_LINKM; // found LinkM
   }
   
   return rc;
}

/*
 *
 */
int linkmboot_reset(void) 
{
    usbDevice_t *dev = NULL;
    int         err = 0;

    if((err = usbOpenDevice(&dev, IDENT_BOOT_VENDOR_NUM, IDENT_BOOT_VENDOR_STRING, IDENT_BOOT_PRODUCT_NUM, IDENT_BOOT_PRODUCT_STRING, 1)) != 0){
        fprintf(stderr, "Error opening LinkMBoot: %s\n", usbErrorMessage(err));
        goto errorOccurred;
    }
    /* and now leave boot loader: */
    buffer.info.reportId = 1;
    usbSetReport(dev, USB_HID_REPORT_TYPE_FEATURE, buffer.bytes, sizeof(buffer.info));
    /* Ignore errors here.If the device reboots before we poll the response,
     * this request fails.
     */
errorOccurred:
    if(dev != NULL)
        usbCloseDevice(dev);
    return err;
}

/*
 *
 */
int linkmboot_uploadFromFile(const char* file, char leaveBootloader)
{
    char dataBuffer[65536 + 256];    /* buffer for file data */
    int  startAddress, endAddress;
    startAddress = sizeof(dataBuffer);
    endAddress = 0;
    memset(dataBuffer, -1, sizeof(dataBuffer));
    if(parseIntelHex(file, dataBuffer, &startAddress, &endAddress))
        return -1;
    if(startAddress >= endAddress){
        fprintf(stderr, "No data in input file, exiting.\n");
        return -2;
    }
    if(linkmboot_uploadData(dataBuffer,startAddress,endAddress,leaveBootloader))
        return -3;
    return 0;
}


/*
 *
 */
int linkmboot_uploadData(char *dataBuffer, int startAddr,int endAddr,char leaveBootloader)
{
usbDevice_t *dev = NULL;
int         err = 0, len, mask, pageSize, deviceSize;

    if((err = usbOpenDevice(&dev, IDENT_BOOT_VENDOR_NUM, IDENT_BOOT_VENDOR_STRING, IDENT_BOOT_PRODUCT_NUM, IDENT_BOOT_PRODUCT_STRING, 1)) != 0){
        fprintf(stderr, "Error opening LinkMBoot: %s\n", usbErrorMessage(err));
        goto errorOccurred;
    }
    len = sizeof(buffer);
    if((err = usbGetReport(dev, USB_HID_REPORT_TYPE_FEATURE, 1, buffer.bytes, &len)) != 0){
        fprintf(stderr, "Error reading page size: %s\n", usbErrorMessage(err));
        goto errorOccurred;
    }
    if(len < sizeof(buffer.info)){
        fprintf(stderr, "Not enough bytes in device info report (%d instead of %d)\n", len, (int)sizeof(buffer.info));
        err = -1;
        goto errorOccurred;
    }
    pageSize = getUsbInt(buffer.info.pageSize, 2);
    deviceSize = getUsbInt(buffer.info.flashSize, 4);
    printf("Page size   = %d (0x%x)\n", pageSize, pageSize);
    printf("Device size = %d (0x%x); %d bytes remaining\n", deviceSize, deviceSize, deviceSize - 2048);
    if(endAddr > deviceSize - 2048){
        fprintf(stderr, "Data (%d bytes) exceeds remaining flash size!\n", endAddr);
        err = -1;
        goto errorOccurred;
    }
    if(pageSize < 128){
        mask = 127;
    }else{
        mask = pageSize - 1;
    }
    startAddr &= ~mask;                  /* round down */
    endAddr = (endAddr + mask) & ~mask;  /* round up */
    printf("Uploading %d (0x%x) bytes starting at %d (0x%x)\n", endAddr - startAddr, endAddr - startAddr, startAddr, startAddr);
    while(startAddr < endAddr){
        buffer.data.reportId = 2;
        memcpy(buffer.data.data, dataBuffer + startAddr, 128);
        setUsbInt(buffer.data.address, startAddr, 3);
        printf("\r0x%05x ... 0x%05x", startAddr, startAddr + (int)sizeof(buffer.data.data));
        fflush(stdout);
        if((err = usbSetReport(dev, USB_HID_REPORT_TYPE_FEATURE, buffer.bytes, sizeof(buffer.data))) != 0){
            fprintf(stderr, "Error uploading data block: %s\n", usbErrorMessage(err));
            goto errorOccurred;
        }
        startAddr += sizeof(buffer.data.data);
    }
    printf("\n");
    if(leaveBootloader){
        linkmboot_reset();
    }
errorOccurred:
    if(dev != NULL)
        usbCloseDevice(dev);
    return err;
}



// ----------------------------
/*
int linkmboot_checkForLinkM(void) 
{
    usbDevice_t *dev = NULL;
    int         err = 0;

    if((err = usbOpenDevice(&dev, IDENT_VENDOR_NUM, IDENT_VENDOR_STRING, 
                            IDENT_PRODUCT_NUM, IDENT_PRODUCT_STRING, 1)) != 0){
        fprintf(stderr, "Error opening LinkM: %s\n", usbErrorMessage(err));
        goto errorOccurred;
    }

errorOccurred:
    if(dev != NULL)
        usbCloseDevice(dev);
    return err;
}
*/

/* ------------------------------------------------------------------------- */

int  parseUntilColon(FILE *fp)
{
int c;

    do{
        c = getc(fp);
    }while(c != ':' && c != EOF);
    return c;
}

int  parseHex(FILE *fp, int numDigits)
{
int     i;
char    temp[9];

    for(i = 0; i < numDigits; i++)
        temp[i] = getc(fp);
    temp[i] = 0;
    return strtol(temp, NULL, 16);
}

/* ------------------------------------------------------------------------- */

int  parseIntelHex(const char *hexfile, char buffer[65536 + 256], int *startAddr, int *endAddr)
{
int     address, base, d, segment, i, lineLen, sum;
FILE    *input;

    input = fopen(hexfile, "r");
    if(input == NULL){
        fprintf(stderr, "error opening %s: %s\n", hexfile, strerror(errno));
        return 1;
    }
    while(parseUntilColon(input) == ':'){
        sum = 0;
        sum += lineLen = parseHex(input, 2);
        base = address = parseHex(input, 4);
        sum += address >> 8;
        sum += address;
        sum += segment = parseHex(input, 2);  /* segment value? */
        if(segment != 0)    /* ignore lines where this byte is not 0 */
            continue;
        for(i = 0; i < lineLen ; i++){
            d = parseHex(input, 2);
            buffer[address++] = d;
            sum += d;
        }
        sum += parseHex(input, 2);
        if((sum & 0xff) != 0){
            fprintf(stderr, "Warning: Checksum error between address 0x%x and 0x%x\n", base, address);
        }
        if(*startAddr > base)
            *startAddr = base;
        if(*endAddr < address)
            *endAddr = address;
    }
    fclose(input);
    return 0;
}


/* ------------------------------------------------------------------------- */

char    *usbErrorMessage(int errCode)
{
static char buffer[80];

    switch(errCode){
        case USB_ERROR_ACCESS:      return "Access to device denied";
        case USB_ERROR_NOTFOUND:    return "The specified device was not found";
        case USB_ERROR_BUSY:        return "The device is used by another application";
        case USB_ERROR_IO:          return "Communication error with device";
        default:
            sprintf(buffer, "Unknown USB error %d", errCode);
            return buffer;
    }
    return NULL;    /* not reached */
}

int  getUsbInt(char *buffer, int numBytes)
{
int shift = 0, value = 0, i;

    for(i = 0; i < numBytes; i++){
        value |= ((int)*buffer & 0xff) << shift;
        shift += 8;
        buffer++;
    }
    return value;
}

void setUsbInt(char *buffer, int value, int numBytes)
{
int i;

    for(i = 0; i < numBytes; i++){
        *buffer++ = value;
        value >>= 8;
    }
}

