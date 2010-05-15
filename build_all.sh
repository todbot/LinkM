#!/bin/bash

# FIXME: doesn't work for all OS types

pushd bootloadHID/commandline
make clean && make
popd

pushd c_host
make clean && make
popd

pushd java_host
make clean && make jar && make processing
popd
