#!/bin/sh
#
# you must type "make jar" before this script will work
#

if [ -e libtargets/linkm.jar ]; then
#    java -d32 -Djava.library.path=libtargets -jar libtargets/linkm.jar $*
    java -d32 -Djava.library.path=libtargets -jar libtargets/linkm.jar $*
else 
    echo "cannot run. make the jar with 'make jar' please"
fi
