#!/bin/bash
# Install Duse.

mkdir -p /usr/lib/duse
cp -Rv lib/* /usr/lib/duse

cp -v bin/duse /usr/bin
