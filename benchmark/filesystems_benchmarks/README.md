# filesystems benchmarks

A set of scripts for filesystem benchmark and comparison performance with different options enabled.

**WARNING! Running this file may cause a potential data loss and assumes you accept that you know what you're doing. All
actions with this script at your own risk.**

## usage:

1. Most of the scripts requires rsync to be installed.
2. Parallel testing scripts requires gnu parallel: `apt-get install parallel`.
3. Set your variables inside the script (for your disk topology, mount points, file to test on, etc...) as shown in
[variable](#variables) section.
4. Run and get something like:
```
Testing: disks=sdc1/sdd1 in parrallel | autodefrag,space_cache=v2,ssd,ssd_spread
write 3 copies:
 21,478,375,424 100%  513.93MB/s    0:00:39 (xfr#1, to-chk=0/1)
 21,478,375,424 100%  497.14MB/s    0:00:41 (xfr#1, to-chk=0/1)   load average: 2,77, 1,54, 1,50

 21,478,375,424 100%  498.00MB/s    0:00:41 (xfr#1, to-chk=0/1)
 21,478,375,424 100%  490.62MB/s    0:00:41 (xfr#1, to-chk=0/1)   load average: 3,70, 2,14, 1,72

 21,478,375,424 100%  507.54MB/s    0:00:40 (xfr#1, to-chk=0/1)
 21,478,375,424 100%  495.04MB/s    0:00:41 (xfr#1, to-chk=0/1)   load average: 3,48, 2,53, 1,92

read 3 copies:
 21,478,375,424 100%  437.98MB/s    0:00:46 (xfr#1, to-chk=0/1)
 21,478,375,424 100%  436.84MB/s    0:00:46 (xfr#1, to-chk=0/1)   load average: 3,17, 2,72, 2,08

 21,478,375,424 100%  446.55MB/s    0:00:45 (xfr#1, to-chk=0/1)          
 21,478,375,424 100%  445.75MB/s    0:00:45 (xfr#1, to-chk=0/1)   load average: 3,41, 2,86, 2,16 

 21,478,375,424 100%  446.55MB/s    0:00:45 (xfr#1, to-chk=0/1)          
 21,478,375,424 100%  445.75MB/s    0:00:45 (xfr#1, to-chk=0/1)   load average: 3,41, 2,86, 2,16 
```

## variables:

Edit script variables to set-up script(s):

- **ZFS_POOL_NAME** (e.g. `"ssd"`): ZFS pool name.
- **POOL_PATH** (e.g. `"/mnt/ssd"`): Mount path for the ZFS pool or btrfs filesystem.
- **FILENAME** (e.g. `"testfile"`): File to check performance within.
- **RAMDISK_PATH** (e.g. `"/mnt/ramdisk"`): Mount path for ramdisk (tempfs).
- **SOURCE_FILE_PATH** (e.g. `"/var/lib/libvirt/images"`): A source path where testfile (see **FILENAME**) for copy to 
ramdisk.
- **BTRFS_MOUNT_OPTIONS** (e.g. `"autodefrag,space_cache=v2,ssd,ssd_spread"`): Mount options for BTRFS filesystems.
- **RAMDISK_SIZE** (e.g. `220`): Ramdisk size in gigabytes.
- **BLOCK_DEVICES_NUMBER** (e.g. `10`): Number of block devices to benchmark.
- **BLOCK_DEVICE_NAME** (e.g. `"sda"`): Name of block device for single disk tests.
- **BLOCK_DEVICES** (e.g. `"/dev/sdc /dev/sde /dev/sdg /dev/sdi"`): Space separated block devices list to perform tests
with.
- **ZFS_POOL_TOPOLOGY** (e.g. `"mirror sdc sde mirror sdg sdi"`): ZFS pool topology to create and perform tests with.
- **BLOCK_DEVICES_START_LETTER** (e.g. `"a"`): First letter of block devices sequence to benchmark (`a` will be an 
`sda`).
- **BLOCK_DEVICES_END_LETTER** (e.g. `"j"`): Last letter of block devices sequence to benchmark.
- **NUMBER_OF_ITERATIONS** (e.g. `3`): Number of write/read iterations.
- **ZFS_ATIME_OPTION** (`off` or `on`): Disable/enable atime option on ZFS pool.
- **ZFS_DEDUP_OPTION** (`off` or `on`): Disable/enable deduplication option on ZFS pool.
- **ZFS_COMPRESSION_OPTION** (`on`, `off`, `lzjb`, `gzip`, `gzip-[1-9]`, `zle` or `lz4`): Enable, disable or specify
compression algorythm for ZFS pool filesystem compression option.
- **RAID1_BLOCK_DEVICES** (e.g. `"/dev/sda /dev/sdb"`): Block devices of RAID1.
- **ZFS_MIRROR1_TOPOLOGY** (e.g. `"mirror sda sdb"`): ZFS pool mirror 1 devices.
- **ZFS_MIRROR2_TOPOLOGY** (e.g. `"mirror sdc sde"`): ZFS pool mirror 2 devices.

## contents:

- [**btrfs_raid10_performance.sh**](btrfs_raid10_performance.sh) - test performance of btrfs radi10.
- [**btrfs_vs_zfs_raid1_vs_raid10_options_performance.sh**](btrfs_vs_zfs_raid1_vs_raid10_options_performance.sh) -
Comparison of two or four disks btrfs raid10 with different data layout vs one or two mirrored ZFS pools performance.
- [**README.md**](README.md) - this file.
- [**single_btrfs_disk_performance.sh**](single_btrfs_disk_performance.sh) - test performance of btrfs filesystem placed on
single disk (e.g. if you wish to test SSD performance of the disk).
- [**single_btrfs_disks_with_parallel_streams_performance.sh**](single_btrfs_disks_with_parallel_streams_performance.sh) -
test several single disks in parallel (e.g. if you wish to test your hardware disk controller speed).
- [**zfs_mirrors_performance.sh**](zfs_mirrors_performance.sh) - test performance of ZFS mirror pools (e.g. if you wish to
test RADI1, RAID10, etc...)
