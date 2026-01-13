#!/bin/sh

# Mushroom farming simulation game.
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

if [ $# -lt 1 ]; then
    echo "USAGE: $0 [NAMETABLE]"
    exit 1
fi

builddir=build
datadir=data

name=christmas.nes
dbgfile=christmas.dbg

srcdir=src
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

i=$1

nam=$datadir/title.nam.rle
echo "-- Converting ${i} to ${nam}..."
mkdir -p $(dirname $nam)
utils/rle/rle $i $nam
if [ $? -ne 0 ]; then
    echo "-- Build failed with exit code $?!"
    echo "-- Exiting $rootdir..."
    cd $orgdir
    exit $?
fi

echo "-- Generating a mask of the tilemap..."
utils/tilemap_mask/tilemap_mask $i $datadir/title.nam.bin

echo "-- Converting the tiles..."
utils/rle/rle src/chr.chr $datadir/chr.chr.rle

echo "-- Calculating the usage of each tile..."
utils/tile_usage/tile_usage src/chr.chr $datadir/chr.chr.bin

echo "-- Assembling the source files..."

objfiles=()

for i in $(find $srcdir -mindepth 1 -type f -name "*.s"); do
    obj=$builddir/${i#$srcdir*}.obj
    echo "-- Assembling ${i} to ${obj}..."
    mkdir -p $(dirname $obj)
    ca65 $i -o $obj -W 1 -g
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
