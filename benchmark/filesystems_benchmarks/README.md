# filesystems benchmarks

A set of scripts for filesystem benchmark and comparison performance with different options enabled.

## variables and usage:

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

## contents:

- [**btrfs_raid10_performance**](btrfs_raid10_performance.sh) - test performance of btrfs radi10.
- [**README.md**](README.md) - this file.
