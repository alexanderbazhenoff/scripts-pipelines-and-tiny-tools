backup btrfs filesystem using snapshot
======================================

**WARNING! Running this file you accept that you know what you're doing. All actions with this script are at your own 
risk.**

Example of how to 
[perform backup of btrfs filesystem using snapshot(s)](https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/Incremental_Backup.html).
Before you begin check your kernel version,
[btrfs status](https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/Status.html) and
[btrfs changelog](https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/Changelog.html).
Some old version may have a non-working functional.

Variables inside a script:

- **SOURCE_FILESYSTEM_PATH** (e.g. `"/mnt/data/ssd/folder"`): Source btrfs filesystem to create snapshot from.
- **BACKUP_FILESYSTEM_PATH** (e.g `"/mnt/data/backup"`): Destination filesystem to send created snapshot. In general 
this is backup path.
- **SNAPSHOTS_PATH** (e.g. `"/mnt/data/ssd/.snapshots"`): Temporary filesystem to create snapshot.
