#!/usr/bin/env bash


# Single btrfs disk performance testing. Performs several iterations of write/read using ramdisk.
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
BLOCK_DEVICE_NAME="sdg1"
BTRFS_MOUNT_OPTIONS="autodefrag,space_cache=v2,ssd,ssd_spread"
RAMDISK_SIZE=62           # in gigabytes
NUMBER_OF_ITERATIONS=3


# perform write-read with rsync
test_wr() {

  # clean files from pool
  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    rm -f "${POOL_PATH}/${FILENAME}-${i}"
  done

  # write performance testing
  rm -fv "${RAMDISK_PATH}/*"
  cp "${SOURCE_FILE_PATH}/$FILENAME" "${RAMDISK_PATH}/$FILENAME"
  echo "write 3 copies:"

  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    rsync --info=progress2 "${RAMDISK_PATH}/$FILENAME" "${POOL_PATH}/${FILENAME}-${i}"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
  done

  # read performance testing
  rm -f "${RAMDISK_PATH}/$FILENAME"
  echo "read 3 copies:"
  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    rsync --info=progress2 "${POOL_PATH}/${FILENAME}-${i}" "${RAMDISK_PATH}/$FILENAME"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
    rm -f "${RAMDISK_PATH}/$FILENAME"
  done
}


mkdir $RAMDISK_PATH || true
mount -t tmpfs -o size="$RAMDISK_SIZE"g tmpfs $RAMDISK_PATH
umount "$POOL_PATH" || true
mkdir "$POOL_PATH" || true

wipefs --all -t btrfs /dev/$BLOCK_DEVICE_NAME
mkfs.btrfs /dev/$BLOCK_DEVICE_NAME -f
partprobe
btrfs filesystem show
mount -o $BTRFS_MOUNT_OPTIONS /dev/$BLOCK_DEVICE_NAME $POOL_PATH
printf "\n\nTesting: disks=%s | %s\n" "$BLOCK_DEVICE_NAME" "$BTRFS_MOUNT_OPTIONS"
test_wr
sync
umount "$POOL_PATH"
