#!/usr/bin/env bash


# Comparison of two or four disks btrfs raid10 with different data layout vs one or two mirrored
# ZFS pools performance. Performs several iterations of write/read using ramdisk.
# -------------------------------------------------------------------------------------------------
# Running this file may cause a potential data loss and assumes you accept that you know what
# you're doing. All actions with this script at your own risk.

# -------------------------------------------------------------------------------------------------
# This Source Code Form is subject to the terms of the BSD 3-Clause License. You can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-and-tools/blob/master/LICENSE


NUMBER_OF_ITERATIONS=5
POOL_NAME="ssd"
POOL_PATH="/mnt/$POOL_NAME"
FILENAME="vm_test_image.qcow2"
RAMDISK_PATH="/mnt/ramdisk"
RAMDISK_SIZE=62
SOURCE_FILE_PATH="/root"
BTRFS_MOUNT_OPTIONS="autodefrag,space_cache=v2,noatime"
BLOCK_DEVICES="/dev/sda /dev/sdb /dev/sdc /dev/sde"
RAID1_BLOCK_DEVICES="/dev/sda /dev/sdb"
ZFS_MIRROR1_TOPOLOGY="mirror sda sdb"
ZFS_MIRROR2_TOPOLOGY="mirror sdc sde"
ZFS_ATIME_OPTION="off"         # off or on
ZFS_DEDUP_OPTION="off"         # off or on
ZFS_COMPRESSION_OPTION="off"   # on | off | lzjb | gzip | gzip-[1-9] | zle | lz4


# perform write-read with rsync
testWR() {

  # clean files from pool
  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    rm -f "${POOL_PATH}/${FILENAME}-${i}"
  done

  # write performance testing
  rm -fv "${RAMDISK_PATH}/*"
  unzip -j "${SOURCE_FILE_PATH}/${FILENAME}.zip" -d "${RAMDISK_PATH}/$FILENAME"
  mv "${RAMDISK_PATH}/${FILENAME}" "${RAMDISK_PATH}/${FILENAME}-dir"
  mv "${RAMDISK_PATH}/${FILENAME}-dir/${FILENAME}" "${RAMDISK_PATH}/$FILENAME"
  rm -rf "${RAMDISK_PATH}/${FILENAME}-dir"
  echo "write copies:"

  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    rsync --info=progress2 "${RAMDISK_PATH}/${FILENAME}" "${POOL_PATH}/${FILENAME}-${i}"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
  done

  # read performance testing
  rm -f "${RAMDISK_PATH}/$FILENAME"
  echo "read copies:"
  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    rsync --info=progress2 "${POOL_PATH}/${FILENAME}-${i}" "${RAMDISK_PATH}/$FILENAME"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
    rm -f "${RAMDISK_PATH}/$FILENAME"
  done
}


# prepare
mkdir $RAMDISK_PATH || true
mount -t tmpfs -o size="${RAMDISK_SIZE}"g tmpfs "$RAMDISK_PATH"
umount $POOL_PATH || true
set -e


# btrfs performance
wipefs --all "$BLOCK_DEVICES" > /dev/zero
mkfs.btrfs -m raid1 -d raid1 "$RAID1_BLOCK_DEVICES" -f
partprobe
btrfs filesystem show
mount -o $BTRFS_MOUNT_OPTIONS "${RAID1_BLOCK_DEVICES// */}" $POOL_PATH
printf "Testing btrfs RAID1: disks=%s | %s" "$RAID1_BLOCK_DEVICES" "$BTRFS_MOUNT_OPTIONS"
testWR
sync
umount $POOL_PATH

wipefs --all "$BLOCK_DEVICES" > /dev/zero
mkfs.btrfs -m raid10 -d raid10 "$BLOCK_DEVICES" -f
partprobe
btrfs filesystem show
mount -o $BTRFS_MOUNT_OPTIONS "${BLOCK_DEVICES// */}" $POOL_PATH
printf "Testing btrfs RAID10: disks=%s (-m raid10 -d raid10) | %s" "$BLOCK_DEVICES" "$BTRFS_MOUNT_OPTIONS"
testWR
sync
umount $POOL_PATH

wipefs --all "$BLOCK_DEVICES" > /dev/zero
mkfs.btrfs -m raid1 -d raid10 "$BLOCK_DEVICES" -f
partprobe
btrfs filesystem show
mount -o $BTRFS_MOUNT_OPTIONS "${BLOCK_DEVICES// */}" $POOL_PATH
printf "Testing btrfs RAID10: disks=%s (-m raid1 -d raid10) | %s" "$BLOCK_DEVICES" "$BTRFS_MOUNT_OPTIONS"
testWR
sync
umount $POOL_PATH

wipefs --all "$BLOCK_DEVICES" > /dev/zero
mkfs.btrfs -m raid10 -d raid1 "$BLOCK_DEVICES" -f
partprobe
btrfs filesystem show
mount -o $BTRFS_MOUNT_OPTIONS "${BLOCK_DEVICES// */}" $POOL_PATH
printf "Testing btrfs RAID10: disks=%s (-m raid10 -d raid1) | %s" "$BLOCK_DEVICES" "$BTRFS_MOUNT_OPTIONS"
testWR
sync
umount $POOL_PATH


# zfs performance
wipefs --all "$BLOCK_DEVICES" > /dev/zero
zpool create $POOL_NAME "$ZFS_MIRROR1_TOPOLOGY" -f
zfs set mountpoint=$POOL_PATH $POOL_NAME
zfs set atime=$ZFS_ATIME_OPTION $POOL_NAME
zfs set compression=$ZFS_COMPRESSION_OPTION $POOL_NAME
zfs set dedup=$ZFS_DEDUP_OPTION $POOL_NAME
printf "Testing zfs RAID1: dedup=%s, compress=%s, atime=%s, disks=%s" "$ZFS_DEDUP_OPTION" "$ZFS_COMPRESSION_OPTION" \
  "$ZFS_ATIME_OPTION" "$ZFS_MIRROR1_TOPOLOGY"
testWR
zpool destroy $POOL_NAME

wipefs --all "$BLOCK_DEVICES" > /dev/zero
zpool create $POOL_NAME "$ZFS_MIRROR1_TOPOLOGY" "$ZFS_MIRROR2_TOPOLOGY" -f
zfs set mountpoint=$POOL_PATH $POOL_NAME
zfs set atime=$ZFS_ATIME_OPTION $POOL_NAME
zfs set compression=$ZFS_COMPRESSION_OPTION $POOL_NAME
zfs set dedup=$ZFS_DEDUP_OPTION $POOL_NAME
printf "Testing zfs RAID1: dedup=%s, compress=%s, atime=%s, disks=%s" "$ZFS_DEDUP_OPTION" "$ZFS_COMPRESSION_OPTION" \
  "$ZFS_ATIME_OPTION" "$ZFS_MIRROR1_TOPOLOGY"
testWR
zpool destroy $POOL_NAME
