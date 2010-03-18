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
    fprintf(stderr, "usage: %s [-r] <intel-hexfile>\n", PROGNAME);
    exit(0);
}

int main(int argc, char **argv)
{
    char *file = NULL; 
    char checkLinkM = 0;
    char leaveBootloader = 0;

    int ch;
    while( (ch = getopt(argc,argv, "chr") ) != -1 ) {
        switch(ch) {
        case 'h':
            printUsage(); //argv[0]);
            break;
        case 'r':
            leaveBootloader = 1;
            break;
        case 'c':
            checkLinkM = 1;
            break;
        }
    }
    argc -= optind; 
    argv += optind;
    if( argc < 1 && !(leaveBootloader || checkLinkM) ) {
        printUsage();
    }

    if( argc == 1 ) {
        file = argv[0];
    }

    if( file ) {
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
    }

    if( leaveBootloader ) {
        printf("Switching from LinkMBoot to LinkM...\n");
        resetLinkMBoot();
    }

    if( checkLinkM ) { 
        printf("Checking for LinkM...\n");
        //msleep( 20000 ); // sleep m milliseconds
        if( checkForLinkM() ) {
            return 1;
        }
        printf("LinkM Found\n");
    }

    return 0;
}

/* ------------------------------------------------------------------------- */


