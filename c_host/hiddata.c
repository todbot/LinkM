/* Name: hiddata.c
 * Author: Christian Starkjohann
 * Creation Date: 2008-04-11
 * Tabsize: 4
 * Copyright: (c) 2008 by OBJECTIVE DEVELOPMENT Software GmbH
 * License: GNU GPL v2 (see License.txt), GNU GPL v3 or proprietary (CommercialLicense.txt)
 *
 * Modified 2026, Tod Kurt, ThingM:
 *   Replaced the Unix/macOS implementation (formerly libusb) with hidapi.
 *   The Windows implementation (Win32 HID API) is unchanged.
 *   Motivation: hidapi uses IOHIDManager on macOS, which accesses the HID
 *   interface directly and coexists with AppleUSBCDC holding the CDC
 *   interface — eliminating the need to disable CDC in the firmware.
 *   The public API (usbhidOpenDevice / usbhidCloseDevice / usbhidSetReport /
 *   usbhidGetReport) is unchanged; only the Unix #else block was rewritten.
 */

#include <stdio.h>
#include "hiddata.h"

/* ######################################################################## */
#if defined(WIN32) /* ##################################################### */
/* ######################################################################## */

#include <windows.h>
#include <setupapi.h>
#include "hidsdi.h"
//#include <ddk/hidpi.h>

#ifdef DEBUG
#define DEBUG_PRINT(arg)    printf arg
#else
#define DEBUG_PRINT(arg)
#endif

/* ------------------------------------------------------------------------ */

static void convertUniToAscii(char *buffer)
{
unsigned short  *uni = (void *)buffer;
char            *ascii = buffer;

    while(*uni != 0){
        if(*uni >= 256){
            *ascii++ = '?';
        }else{
            *ascii++ = *uni++;
        }
    }
    *ascii++ = 0;
}

int usbhidOpenDevice(usbDevice_t **device, int vendor, char *vendorName, int product, char *productName, int usesReportIDs)
{
GUID                                hidGuid;        /* GUID for HID driver */
HDEVINFO                            deviceInfoList;
SP_DEVICE_INTERFACE_DATA            deviceInfo;
SP_DEVICE_INTERFACE_DETAIL_DATA     *deviceDetails = NULL;
DWORD                               size;
int                                 i, openFlag = 0;  /* may be FILE_FLAG_OVERLAPPED */
int                                 errorCode = USBOPEN_ERR_NOTFOUND;
HANDLE                              handle = INVALID_HANDLE_VALUE;
HIDD_ATTRIBUTES                     deviceAttributes;

    HidD_GetHidGuid(&hidGuid);
    deviceInfoList = SetupDiGetClassDevs(&hidGuid, NULL, NULL, DIGCF_PRESENT | DIGCF_INTERFACEDEVICE);
    deviceInfo.cbSize = sizeof(deviceInfo);
    for(i=0;;i++){
        if(handle != INVALID_HANDLE_VALUE){
            CloseHandle(handle);
            handle = INVALID_HANDLE_VALUE;
        }
        if(!SetupDiEnumDeviceInterfaces(deviceInfoList, 0, &hidGuid, i, &deviceInfo))
            break;  /* no more entries */
        /* first do a dummy call just to determine the actual size required */
        SetupDiGetDeviceInterfaceDetail(deviceInfoList, &deviceInfo, NULL, 0, &size, NULL);
        if(deviceDetails != NULL)
            free(deviceDetails);
        deviceDetails = malloc(size);
        deviceDetails->cbSize = sizeof(*deviceDetails);
        /* this call is for real: */
        SetupDiGetDeviceInterfaceDetail(deviceInfoList, &deviceInfo, deviceDetails, size, &size, NULL);
        DEBUG_PRINT(("checking HID path \"%s\"\n", deviceDetails->DevicePath));
#if 0
        /* If we want to access a mouse our keyboard, we can only use feature
         * requests as the device is locked by Windows. It must be opened
         * with ACCESS_TYPE_NONE.
         */
        handle = CreateFile(deviceDetails->DevicePath, ACCESS_TYPE_NONE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, openFlag, NULL);
#endif
        /* attempt opening for R/W -- we don't care about devices which can't be accessed */
        handle = CreateFile(deviceDetails->DevicePath, GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ|FILE_SHARE_WRITE, NULL, OPEN_EXISTING, openFlag, NULL);
        if(handle == INVALID_HANDLE_VALUE){
            DEBUG_PRINT(("opening failed: %d\n", (int)GetLastError()));
            /* errorCode = USBOPEN_ERR_ACCESS; opening will always fail for mouse -- ignore */
            continue;
        }
        deviceAttributes.Size = sizeof(deviceAttributes);
        HidD_GetAttributes(handle, &deviceAttributes);
        DEBUG_PRINT(("device attributes: vid=%d pid=%d\n", deviceAttributes.VendorID, deviceAttributes.ProductID));
        if(deviceAttributes.VendorID != vendor || deviceAttributes.ProductID != product)
            continue;   /* ignore this device */
        errorCode = USBOPEN_ERR_NOTFOUND;
        if(vendorName != NULL && productName != NULL){
            char    buffer[512];
            if(!HidD_GetManufacturerString(handle, buffer, sizeof(buffer))){
                DEBUG_PRINT(("error obtaining vendor name\n"));
                errorCode = USBOPEN_ERR_IO;
                continue;
            }
            convertUniToAscii(buffer);
            DEBUG_PRINT(("vendorName = \"%s\"\n", buffer));
            if(strcmp(vendorName, buffer) != 0)
                continue;
            if(!HidD_GetProductString(handle, buffer, sizeof(buffer))){
                DEBUG_PRINT(("error obtaining product name\n"));
                errorCode = USBOPEN_ERR_IO;
                continue;
            }
            convertUniToAscii(buffer);
            DEBUG_PRINT(("productName = \"%s\"\n", buffer));
            if(strcmp(productName, buffer) != 0)
                continue;
        }
        break;  /* we have found the device we are looking for! */
    }
    SetupDiDestroyDeviceInfoList(deviceInfoList);
    if(deviceDetails != NULL)
        free(deviceDetails);
    if(handle != INVALID_HANDLE_VALUE){
        *device = (usbDevice_t *)handle;
        errorCode = 0;
    }
    return errorCode;
}

/* ------------------------------------------------------------------------ */

void    usbhidCloseDevice(usbDevice_t *device)
{
    CloseHandle((HANDLE)device);
}

/* ------------------------------------------------------------------------ */

int usbhidSetReport(usbDevice_t *device, char *buffer, int len)
{
BOOLEAN rval;

    rval = HidD_SetFeature((HANDLE)device, buffer, len);
    return rval == 0 ? USBOPEN_ERR_IO : 0;
}

/* ------------------------------------------------------------------------ */

int usbhidGetReport(usbDevice_t *device, int reportNumber, char *buffer, int *len)
{
BOOLEAN rval = 0;

    buffer[0] = reportNumber;
    rval = HidD_GetFeature((HANDLE)device, buffer, *len);
    return rval == 0 ? USBOPEN_ERR_IO : 0;
}

/* ------------------------------------------------------------------------ */

/* ######################################################################## */
#else /* defined WIN32 #################################################### */
/* ######################################################################## */

#include <stdlib.h>
#include <string.h>
#include <wchar.h>
#include <hidapi.h>

struct usbDevice {
    hid_device *hid;
    int         usesReportIDs;
};

/* ------------------------------------------------------------------------- */

int usbhidOpenDevice(usbDevice_t **device, int vendor, char *vendorName, int product, char *productName, int usesReportIDs)
{
    struct hid_device_info *devs, *cur;
    hid_device *handle = NULL;

    if (hid_init() != 0) {
        fprintf(stderr, "Warning: cannot initialize hidapi\n");
        return USBOPEN_ERR_IO;
    }

    devs = hid_enumerate((unsigned short)vendor, (unsigned short)product);
    cur  = devs;
    while (cur) {
        int nameMatch = 1;
        if (vendorName && productName) {
            char mfr[256]  = {0};
            char prod[256] = {0};
            if (cur->manufacturer_string)
                wcstombs(mfr,  cur->manufacturer_string, sizeof(mfr)  - 1);
            if (cur->product_string)
                wcstombs(prod, cur->product_string,      sizeof(prod) - 1);
            nameMatch = (strcmp(mfr, vendorName) == 0 &&
                         strcmp(prod, productName) == 0);
        }
        if (nameMatch) {
            handle = hid_open_path(cur->path);
            if (handle)
                break;
        }
        cur = cur->next;
    }
    hid_free_enumeration(devs);

    if (!handle) {
        hid_exit();
        return USBOPEN_ERR_NOTFOUND;
    }

    usbDevice_t *dev = malloc(sizeof(usbDevice_t));
    dev->hid           = handle;
    dev->usesReportIDs = usesReportIDs;
    *device = dev;
    return 0;
}

/* ------------------------------------------------------------------------- */

void usbhidCloseDevice(usbDevice_t *device)
{
    if (!device)
        return;
    hid_close(device->hid);
    free(device);
    hid_exit();
}

/* ------------------------------------------------------------------------- */

int usbhidSetReport(usbDevice_t *device, char *buffer, int len)
{
    /* buffer[0] is the report ID; hidapi expects the same layout */
    int r = hid_send_feature_report(device->hid, (unsigned char *)buffer, len);
    return (r < 0) ? USBOPEN_ERR_IO : 0;
}

/* ------------------------------------------------------------------------- */

int usbhidGetReport(usbDevice_t *device, int reportNumber, char *buffer, int *len)
{
    buffer[0] = (char)reportNumber;
    int r = hid_get_feature_report(device->hid, (unsigned char *)buffer, *len);
    if (r < 0) {
        fprintf(stderr, "Error reading report: %ls\n", hid_error(device->hid));
        return USBOPEN_ERR_IO;
    }
    *len = r;
    return 0;
}

/* ######################################################################## */
#endif /* defined WIN32 ################################################### */
/* ######################################################################## */
