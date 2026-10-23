#!/bin/sh

# OneCloud (8G eMMC) layout:
#   p1  boot   fat32   KERNEL_PARTSIZE (256M)
#   p2  rootfs ext4    ROOTFS_PARTSIZE (1004M)
#   p3  data   ext4    rest of the eMMC, formatted+mounted on first boot
#
# The data partition is only declared in the MBR. No payload is written for it,
# so the resulting image stays small; /etc/uci-defaults/99-onecloud-storage
# formats and mounts it on the first boot.

set -x
[ $# -eq 5 ] || {
    echo "SYNTAX: $0 <file> <bootfs image> <rootfs image> <bootfs size> <rootfs size>"
    exit 1
}

OUTPUT="$1"
BOOTFS="$2"
ROOTFS="$3"
BOOTFSSIZE="$4"
ROOTFSSIZE="$5"

# size of the data partition in MiB (8GME4R eMMC = 7456MiB)
DATASIZE="${ONECLOUD_DATA_PARTSIZE:-6000}"

head=4
sect=63

set $(ptgen -o $OUTPUT -h $head -s $sect -l 4096 \
	-t c -p ${BOOTFSSIZE}M \
	-t 83 -p ${ROOTFSSIZE}M \
	-t 83 -p ${DATASIZE}M)

BOOTOFFSET="$(($1 / 512))"
BOOTSIZE="$(($2 / 512))"
ROOTFSOFFSET="$(($3 / 512))"
ROOTFSSIZE="$(($4 / 512))"

dd bs=512 if="$BOOTFS" of="$OUTPUT" seek="$BOOTOFFSET" conv=notrunc
dd bs=512 if="$ROOTFS" of="$OUTPUT" seek="$ROOTFSOFFSET" conv=notrunc
