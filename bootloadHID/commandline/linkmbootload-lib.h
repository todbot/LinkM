#ifndef __linkmbootload_lib_h__
#define __linkmbootload_lib_h__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <unistd.h>  // for usleep()

// create the "msleep(m)" func
#ifdef _MINGW32
#include <windows.h>
#define msleep(m) Sleep(m)
#else
#include <unistd.h>
#define msleep(m) usleep(1000*m)
#endif

#define IDENT_BOOT_VENDOR_NUM        0x20A0
#define IDENT_BOOT_PRODUCT_NUM       0x4110
#define IDENT_BOOT_VENDOR_STRING     "ThingM"
#define IDENT_BOOT_PRODUCT_STRING    "LinkMBoot"

#define IDENT_VENDOR_NUM        0x20A0
#define IDENT_PRODUCT_NUM       0x4110
#define IDENT_VENDOR_STRING     "ThingM"
#define IDENT_PRODUCT_STRING    "LinkM"

#define FOUND_LINKM 100
#define FOUND_LINKMBOOT 101


/* ------------------------------------------------------------------------- */

int linkmboot_uploadFromFile(const char* file, char leaveBootloader);
int linkmboot_uploadData(char *dataBuffer, int startAddr, int endAddr,
                         char leaveBootloader);
int linkmboot_findLinkM(void);
int linkmboot_reset(void);
//int linkmboot_checkForLinkM(void) ;




#endif
