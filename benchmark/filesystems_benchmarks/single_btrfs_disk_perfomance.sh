#!/usr/bin/env bash


### Single btrfs disk performance testing. Performs several iterations of write read using ramdisk.
### -----------------------------------------------------------------------------------------------
### Warning! Running this file you accept that you know what you're doing. All actions with this
###          script at your own risk.
### -----------------------------------------------------------------------------------------------
### This Source Code Form is subject to the terms of the MIT License. If a copy of the MPL was not
### distributed with this file, You can obtain one at:
### https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


POOL_PATH="/mnt/ssd"
FILENAME="dit-builder.qcow2"
RAMDISK_PATH="/mnt/ramdisk"
SOURCE_FILE_PATH="/var/lib/libvirt/images"
BLOCK_DEVICE_NAME="sdg1"
BTRFS_MOUNT_OPTIONS="autodefrag,space_cache=v2,ssd,ssd_spread"
RAMDISK_SIZE="62"  # in gygabites


# perform write-read with rsync
test_wr() {
  # clean files from pool
  for i in {1..3}
  do
    rm -f "${POOL_PATH}/${FILENAME}-${i}"
  done
  # write performance testing
  rm -fv "${RAMDISK_PATH}/*"
  cp "${SOURCE_FILE_PATH}/${FILENAME}" "${RAMDISK_PATH}/${FILENAME}"
  echo "write 3 copies:"

  for i in {1..3}
  do
    rsync --info=progress2 "${RAMDISK_PATH}/${FILENAME}" "${POOL_PATH}/${FILENAME}-${i}"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
  done

  # read performance testing
  rm -f "${RAMDISK_PATH}/${FILENAME}"
  echo "read 3 copies:"
  for i in {1..3}
  do
    rsync --info=progress2 "${POOL_PATH}/${FILENAME}-${i}" "${RAMDISK_PATH}/${FILENAME}"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
    rm -f "${RAMDISK_PATH}/${FILENAME}"
  done
}

mount -t tmpfs -o size="$RAMDISK_SIZE"g tmpfs /mnt/ramdisk
umount /mnt/ssd

wipefs --all -t btrfs /dev/$BLOCK_DEVICE_NAME
mkfs.btrfs /dev/$BLOCK_DEVICE_NAME -f
partprobe
btrfs filesystem show
mount -o $BTRFS_MOUNT_OPTIONS /dev/$BLOCK_DEVICE_NAME /mnt/ssd
printf "\n\nTesting: disks=%s | %s\n" "$BLOCK_DEVICE_NAME" "$BTRFS_MOUNT_OPTIONS"
test_wr
sync
umount /mnt/ssd
