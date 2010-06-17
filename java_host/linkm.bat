#
# you must type "make jar" before this script will work
#
@echo off
java -Djava.library.path=libtargets -jar libtargets/linkm.jar $*

