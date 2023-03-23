#!/usr/bin/env bash


### Single btrfs disks performance testing in parallel streams.
### Performs several iterations of write/read using ramdisk.
### -----------------------------------------------------------------------------------------------
### Warning! Running this file you accept that you know what you're doing. All actions with this
###          script at your own risk.
### -----------------------------------------------------------------------------------------------
### This Source Code Form is subject to the terms of the MIT License. If a copy of the MPL was not
### distributed with this file, You can obtain one at:
### https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


POOL_PATH="/mnt/ssd"
FILENAME="testfile"
RAMDISK_PATH="/mnt/ramdisk"
SOURCE_FILE_PATH="/var/lib/libvirt/images"
BTRFS_MOUNT_OPTIONS="autodefrag,space_cache=v2,ssd,ssd_spread"
RAMDISK_SIZE=220                  # in gigabytes
BLOCK_DEVICES_NUMBER=10
BLOCK_DEVICES_START_LETTER="a"    # a is sda
BLOCK_DEVICES_END_LETTER="j"      # j is sdj
NUMBER_OF_ITERATIONS=3            # total number of write/read iterations


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
  printf "\n\n\nWrite 3 copies:"

  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    seq $((BLOCK_DEVICES_NUMBER*2)) | parallel -j $((BLOCK_DEVICES_NUMBER*2)) rsync -r --info=progress2 \
      "${RAMDISK_PATH}/$FILENAME" "${POOL_PATH}{}/${FILENAME}-${i}-{}"
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
  done

  # read performance testing
  rm -f "${RAMDISK_PATH}/$FILENAME"
  printf "\n\n\nRead 3 copies:"
  for ((i=1; i <= NUMBER_OF_ITERATIONS; i++))
  do
    seq $((BLOCK_DEVICES_NUMBER*2)) | parallel -j $((BLOCK_DEVICES_NUMBER*2)) rsync -r --info=progress2 \
      "${POOL_PATH}{}/${FILENAME}-${i}-{}" /dev/null
    uptime | printf "\e[1A\t\t\t\t\t\t\t\t  load %s\n" "$(uptime | sed 's/^.*average:/average:/')"
    sync; echo 3 > /proc/sys/vm/drop_caches
    seq $((BLOCK_DEVICES_NUMBER*2)) | parallel -j $((BLOCK_DEVICES_NUMBER*2)) rm -f "${RAMDISK_PATH}/${FILENAME}-{}"
    sync; echo 3 > /proc/sys/vm/drop_caches
  done
}


mkdir "$RAMDISK_PATH" || true
mount -t tmpfs -o size="${RAMDISK_SIZE}"g tmpfs $RAMDISK_PATH
seq $((BLOCK_DEVICES_NUMBER*2)) | parallel -j ${BLOCK_DEVICES_NUMBER} umount ${POOL_PATH}{}
seq $((BLOCK_DEVICES_NUMBER*2)) | parallel -j ${BLOCK_DEVICES_NUMBER} mkdir ${POOL_PATH}{}

DISK_NUMBER=1
for LETTER in $(eval "echo {$BLOCK_DEVICES_START_LETTER..$BLOCK_DEVICES_END_LETTER}")
do
  wipefs --all -t btrfs /dev/sd"$LETTER"1
  mkfs.btrfs /dev/sd"$LETTER"1 -f
  partprobe
  btrfs fiesystem show
  mkdir /mnt/"$POOL_PATH$DISK_NUMBER"
  mount -o "$BTRFS_MOUNT_OPTIONS" /dev/sd"$LETTER"1 /mnt/"$POOL_PATH$DISK_NUMBER"
  (( DISK_NUMBER++ )) || true
  mkdir /mnt/"$POOL_PATH$DISK_NUMBER" || true
  mount -o "${BTRFS_MOUNT_OPTIONS}" /dev/sd"$LETTER"1 /mnt/"$POOL_PATH$DISK_NUMBER"
  (( DISK_NUMBER++ )) || true
done
printf "Testing: %s disks in %s streams | %s" "$BLOCK_DEVICES_NUMBER" "$((BLOCK_DEVICES_NUMBER*2))" \
  "$BTRFS_MOUNT_OPTIONS"
test_wr
sync
seq $BLOCK_DEVICES_NUMBER | parallel -j 2 umount /mnt/"$POOL_PATH"{}
