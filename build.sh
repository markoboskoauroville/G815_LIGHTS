#!/bin/sh
# build.sh: build/g815, the wire to the keyboard (Swift, no library).
cd "$(dirname "$0")" && mkdir -p build && swiftc -O -o build/g815 src/*.swift && echo "built build/g815"
