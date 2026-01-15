#!/bin/sh

# MibiEngineN -- A small template to code NES games.
#
# by Mibi88
#
# This software is licensed under the BSD-3-Clause license:
#
# Copyright 2025 Mibi88
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from this
# software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

builddir=build
datadir=data

name=rom.nes
dbgfile=rom.dbg

srcdirs="src lib"
assetdir=assets

rootdir=$(dirname $0)
orgdir=$(pwd)
echo "-- Entering $rootdir..."
cd $rootdir

echo "-- Building the tools..."
utils/rle/build.sh
utils/tilemap_mask/build.sh
utils/tile_usage/build.sh
if [ $? -ne 0 ]; then
    echo "-- Build failed with exit code $?!"
    echo "-- Exiting $rootdir..."
    cd $orgdir
    exit $?
fi

mkdir -p $builddir
mkdir -p $datadir

echo "-- Converting the nametable..."

for i in $(find $assetdir -type f -name "*.nam"); do
    nam=$datadir/${i#$assetdir*}
    echo "-- Converting ${i} to ${nam}.rle..."
    mkdir -p $(dirname $nam)
    utils/rle/rle $i $nam.rle
    if [ $? -ne 0 ]; then
        echo "-- Build failed with exit code $?!"
        echo "-- Exiting $rootdir..."
        cd $orgdir
        exit $?
    fi

    echo "-- Generating a mask of ${i} to ${nam}.bin..."
    utils/tilemap_mask/tilemap_mask $i $nam.bin
done

for i in $(find $assetdir -type f -name "*.chr"); do
    chr=$datadir/${i#$assetdir*}
    echo "-- Compressing the tiles to ${chr}.rle..."
    utils/rle/rle $i $chr.rle

    echo "-- Writing the usage of each tile in ${i} down in ${chr}.bin..."
    utils/tile_usage/tile_usage $i $chr.bin
done

echo "-- Assembling the source files..."

objfiles=()

for i in $(find $srcdirs -mindepth 1 -type f -name "*.s"); do
    obj=$builddir/${i#$srcdirs*}.obj
    echo "-- Assembling ${i} to ${obj}..."
    mkdir -p $(dirname $obj)
    ca65 $i -o $obj -W 1 -g -I lib
    if [ $? -ne 0 ]; then
        echo "-- Build failed with exit code $?!"
        echo "-- Exiting $rootdir..."
        cd $orgdir
        exit $?
    fi
    objfiles+=($obj)
done

# Linking
echo "-- Linking $name..."
ld65 ${objfiles[@]} -o $name -C nrom.cfg --dbgfile $dbgfile

if [ $? -ne 0 ]; then
    echo "-- Build failed with exit code $?!"
    echo "-- Exiting $rootdir..."
    cd $orgdir
    exit $?
fi

echo "-- Exiting $rootdir..."
cd $orgdir
echo "-- Build succeeded!"
