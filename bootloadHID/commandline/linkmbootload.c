/*
 * linkmbootload -- derived from bootloadHID's main.c
 *
 *
 * Name: main.c
 * Project: AVR bootloader HID
 * Author: Christian Starkjohann
 * Creation Date: 2007-03-19
 * Tabsize: 4
 * Copyright: (c) 2007 by OBJECTIVE DEVELOPMENT Software GmbH
 * License: Proprietary, free under certain conditions. See Documentation.
 * This Revision: $Id: main.c 373 2007-07-04 08:59:36Z cs $
 */

#include <stdio.h>
#include <string.h>
#include <getopt.h>

#include "linkmbootload-lib.h"


/* ------------------------------------------------------------------------- */

static void printUsage()
{
    fprintf(stderr, "usage: %s [-f] [-r] <intel-hexfile>\n", PROGNAME);
    exit(0);
}

int main(int argc, char **argv)
{
    char *file = NULL; 
    char findLinkM = 0;
    char leaveBootloader = 0;

    int ch;
    while( (ch = getopt(argc,argv, "cfhr") ) != -1 ) {
        switch(ch) {
        case 'h':
            printUsage(); //argv[0]);
            break;
        case 'r':
            leaveBootloader = 1;
            break;
        case 'c':
        case 'f':
            findLinkM = 1;
            break;
        }
    }
    argc -= optind; 
    argv += optind;
    if( argc < 1 && !(leaveBootloader || findLinkM) ) {
        printUsage();
    }

    if( argc == 1 ) {
        file = argv[0];
    }

    if( findLinkM ) { 
        printf("Looking for LinkM...\n");
        int rc =  linkmboot_findLinkM();
        if( rc == FOUND_LINKM ) {
            printf("found LinkM");
        } else if( rc == FOUND_LINKMBOOT ) {
            printf("found LinkMBoot");
        }
        else {
            return 1;
        }
        return 0;
    }

    if( file ) {
        int rc = linkmboot_uploadFromFile(file, 0);
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
    }

    if( leaveBootloader ) {
        printf("Switching from LinkMBoot to LinkM...\n");
        linkmboot_reset();
    }
    return 0;
}

/* ------------------------------------------------------------------------- */


