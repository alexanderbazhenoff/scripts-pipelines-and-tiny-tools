# Backup Btrfs Filesystem Using Snapshot

**WARNING! By running this script, you acknowledge that you understand what you are doing. All actions are performed at
your own risk.**

This is an example of how to back up a Btrfs filesystem using
[snapshots](https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/Incremental_Backup.html).

Before getting started, check your kernel version,
the [Btrfs status](https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/Status.html), and the
[Btrfs changelog](https://archive.kernel.org/oldwiki/btrfs.wiki.kernel.org/index.php/Changelog.html).
Older versions may contain broken or incomplete functionality.

Script variables:

- **SOURCE_FILESYSTEM_PATH** (e.g. `"/mnt/data/ssd/folder"`):  
  The source Btrfs filesystem from which to create a snapshot.

- **BACKUP_FILESYSTEM_PATH** (e.g. `"/mnt/data/backup"`):  
  The destination filesystem to which the snapshot will be sent. Typically, this is your backup location.

- **SNAPSHOTS_PATH** (e.g. `"/mnt/data/ssd/.snapshots"`):  
  A temporary location used to store the created snapshots.
