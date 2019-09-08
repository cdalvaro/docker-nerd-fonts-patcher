#!/bin/bash

set -e

# Install libspiro
git clone --branch "${LIBSPIRO_VERSION}" --depth 1 https://github.com/fontforge/libspiro.git && \
    cd libspiro && \
    autoreconf -i && \
    automake --foreign -Wall && \
    ./configure && \
    make install && \
    cd ..

# Install libuninameslist
git clone --depth 1 https://github.com/fontforge/libuninameslist.git && \
    cd libuninameslist && \
    autoreconf -i && \
    automake --foreign && \
    ./configure && \
    make install && \
    cd ..

# Install fontforge
git clone --branch "${FONTFORGE_VERSION}" --depth 1 https://github.com/fontforge/fontforge.git && \
    cd fontforge && \
    ./bootstrap && \
    ./configure && \
    make install && \
    ldconfig && \
    cd ..

# Cleanup
rm -rf ${BUILD_DIR}
