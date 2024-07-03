#!/usr/bin/env bash

# btrfs raid10 performance testing. Performs several iterations of write and read using ramdisk.
# -------------------------------------------------------------------------------------------------
# Running this file may cause a potential data loss and assumes you accept that you know what
# you're doing. All actions with this script at your own risk.

# -------------------------------------------------------------------------------------------------
# This Source Code Form is subject to the terms of the BSD 3-Clause License. You can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

POOL_PATH="/mnt/ssd"
FILENAME="vm_image.qcow2"
RAMDISK_PATH="/mnt/ramdisk"
SOURCE_FILE_PATH="/var/lib/libvirt/images"
BLOCK_DEVICES="/dev/sdc1 /dev/sde1 /dev/sdg1 /dev/sdi1"
BTRFS_MOUNT_OPTIONS="autodefrag,space_cache=v2,ssd,ssd_spread"
RAMDISK_SIZE=62 # in gigabytes

# perform write-read with rsync
test_wr() {

  # clean files from pool
  for i in {1..3}
  do
    rm -f "${POOL_PATH}/${FILENAME}-${i}"
  done

  # write performance testing
  rm -fv "${RAMDISK_PATH}/*"
  cp "${SOURCE_FILE_PATH}/$FILENAME" "${RAMDISK_PATH}/$FILENAME"
  echo "write 3 copies:"

  for i in {1..3}
  do
    rsync --info=progress2 "${RAMDISK_PATH}/$FILENAME" "${POOL_PATH}/${FILENAME}-${i}"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
  done

  # read performance testing
  rm -f "${RAMDISK_PATH}/$FILENAME"
  echo "read 3 copies:"
  for i in {1..3}
  do
    rsync --info=progress2 "${POOL_PATH}/${FILENAME}-${i}" "${RAMDISK_PATH}/$FILENAME"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
    rm -f "${RAMDISK_PATH}/$FILENAME"
  done
}


mkdir $RAMDISK_PATH || true
mount -t tmpfs -o size="$RAMDISK_SIZE"g tmpfs $RAMDISK_PATH
umount $POOL_PATH || true
mkdir "$POOL_PATH" || true

wipefs --all "$BLOCK_DEVICES"
mkfs.btrfs -m raid10 -d "$BLOCK_DEVICES" -f
partprobe
btrfs filesystem show
mount -o $BTRFS_MOUNT_OPTIONS "${BLOCK_DEVICES// */}" $POOL_PATH
printf "\n\nTesting: RAID10 with disks: %s | %s\n" "$BLOCK_DEVICES" "$BTRFS_MOUNT_OPTIONS"
test_wr
sync
umount $POOL_PATH
