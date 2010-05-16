#!/bin/bash

# build all the host-side code

pushd bootloadHID/commandline
make clean && make
popd

pushd c_host
make clean && make
popd

pushd java_host
make clean && make jar && make processing
popd
