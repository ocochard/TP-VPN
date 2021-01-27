#!/bin/sh

USERBOOT="userboot.so"
IMG="disk0.img"
######
# Install mode
#BOOTVOLUME="/Users/ocochard/Downloads/memstick.img"
#BOOT_HDD="-s 3:0,virtio-blk,$BOOTVOLUME"
# running mode
BOOTVOLUME=$IMG
######
FIRMWARE="BHYVE_UEFI.fd"
MEM="-m 1G"
SMP="-c 2"
NET="-s 2:0,virtio-net"
IMG_HDD="-s 4,virtio-blk,$IMG"
PCI_DEV="-s 0:0,hostbridge -s 31,lpc"
LPC_DEV="-l com1,stdio"
ACPI="-A"
UUID="-U deadbeef-dead-dead-dead-deaddeafbeef"
HYPERKIT_BIN=`type -p hyperkit`

# FreeBSD
$HYPERKIT_BIN $ACPI $MEM $SMP $PCI_DEV $LPC_DEV $NET $IMG_CD $IMG_HDD $BOOT_HDD $UUID -f fbsd,$USERBOOT,$BOOTVOLUME
