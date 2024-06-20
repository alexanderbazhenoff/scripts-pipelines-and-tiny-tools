#!/usr/bin/env bash


# ZFS pool performance testing. Performs several iterations of write and read using ramdisk.
# -------------------------------------------------------------------------------------------------
# Running this file may cause a potential data loss and assumes you accept that you know what
# you're doing. All actions with this script at your own risk.

# -------------------------------------------------------------------------------------------------
# This Source Code Form is subject to the terms of the BSD 3-Clause License. You can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE


FILENAME="vm_image.qcow2"
RAMDISK_PATH="/mnt/ramdisk"
SOURCEFILE_PATH="/var/lib/libvirt/images"
RAMDISK_SIZE=62                # in gigabytes

ZFS_POOL_NAME="ssd"
POOL_PATH="/mnt/$ZFS_POOL_NAME"
BLOCK_DEVICES="/dev/sdc /dev/sde /dev/sdg /dev/sdi"
ZFS_POOL_TOPOLOGY="mirror sdc sde mirror sdg sdi"
ZFS_ATIME_OPTION="off"         # off or on
ZFS_DEDUP_OPTION="off"         # off or on
ZFS_COMPRESSION_OPTION="off"   # on | off | lzjb | gzip | gzip-[1-9] | zle | lz4
NUMBER_OF_ITERATIONS=3         # total number of write/read iterations


# perform write-read with rsync
test_wr() {

  # clean files from pool
  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    rm -f "${POOL_PATH}/${FILENAME}-${i}"
  done

  # write performance testing
  rm -fv "${RAMDISK_PATH}/*"
  cp "${SOURCEFILE_PATH}/$FILENAME" "${RAMDISK_PATH}/$FILENAME"
  echo "write 3 copies:"

  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    rsync --info=progress2 "${POOL_PATH}/${FILENAME}-${i}" "${RAMDISK_PATH}/$FILENAME"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync
    echo 3 > /proc/sys/vm/drop_caches
    rm -f "${RAMDISK_PATH}/$FILENAME"
  done
}


mkdir $RAMDISK_PATH || true
mount -t tmpfs -o size="$RAMDISK_SIZE"g tmpfs $RAMDISK_PATH
umount $POOL_PATH || true
mkdir $POOL_PATH || true

wipefs --all "$BLOCK_DEVICES" > /dev/zero
zpool create $ZFS_POOL_NAME "$ZFS_POOL_TOPOLOGY" -f
zfs set mountpoint="$POOL_PATH" $ZFS_POOL_NAME
zfs set atime=$ZFS_ATIME_OPTION $ZFS_POOL_NAME
zfs set dedup=$ZFS_DEDUP_OPTION $ZFS_POOL_NAME
zfs set compression=$ZFS_COMPRESSION_OPTION $ZFS_POOL_NAME
printf "\n\nTesting zfs: dedup=%s, compress=%s, atime=%s | %s\n" "$ZFS_DEDUP_OPTION" "$ZFS_COMPRESSION_OPTION" \
  "$ZFS_ATIME_OPTION" "$ZFS_POOL_TOPOLOGY"
test_wr
zpool destroy $ZFS_POOL_NAME
