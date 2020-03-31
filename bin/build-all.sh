#!/bin/bash

set -e

source bin/version.sh

COUNTRIES="US EU433 EU865 CN JP"
#COUNTRIES=US

OUTDIR=release/latest

# We keep all old builds (and their map files in the archive dir)
ARCHIVEDIR=release/archive 

rm -f $OUTDIR/firmware*

mkdir -p $OUTDIR/bins $OUTDIR/elfs

# build the named environment and copy the bins to the release directory
function do_build {
    ENV_NAME=$1
    echo "Building for $ENV_NAME with $PLATFORMIO_BUILD_FLAGS"
    SRCBIN=.pio/build/$ENV_NAME/firmware.bin
    SRCELF=.pio/build/$ENV_NAME/firmware.elf
    rm -f $SRCBIN 
    pio run --environment $ENV_NAME # -v
    cp $SRCBIN $OUTDIR/bins/firmware-$ENV_NAME-$COUNTRY-$VERSION.bin
    cp $SRCELF $OUTDIR/elfs/firmware-$ENV_NAME-$COUNTRY-$VERSION.elf
}

for COUNTRY in $COUNTRIES; do 

    HWVERSTR="1.0-$COUNTRY"
    COMMONOPTS="-DAPP_VERSION=$VERSION -DHW_VERSION_$COUNTRY -DHW_VERSION=$HWVERSTR -Wall -Wextra -Wno-missing-field-initializers -Isrc -Os -DAXP_DEBUG_PORT=Serial"

    export PLATFORMIO_BUILD_FLAGS="$COMMONOPTS"

    do_build "tbeam0.7"
    do_build "ttgo-lora32-v2"
    do_build "ttgo-lora32-v1"
    do_build "tbeam"
    do_build "heltec"
done

# keep the bins in archive also
cp $OUTDIR/firmware* $ARCHIVEDIR

cat >$OUTDIR/curfirmwareversion.xml <<XML
<?xml version="1.0" encoding="utf-8"?>

<!-- This file is kept in source control because it reflects the last stable
release.  It is used by the android app for forcing software updates.  Do not edit.
Generated by bin/buildall.sh -->

<resources>
    <string name="cur_firmware_version">$VERSION</string>
</resources>
XML

rm -f $ARCHIVEDIR/firmware-$VERSION.zip
zip --junk-paths $ARCHIVEDIR/firmware-$VERSION.zip $OUTDIR/bins/firmware-*-$VERSION.* images/system-info.bin bin/device-install.sh

echo BUILT ALL