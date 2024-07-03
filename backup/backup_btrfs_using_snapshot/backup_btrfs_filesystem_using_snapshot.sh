#!/usr/bin/env bash

# Example how to backups btrfs filesystems using snapshots.
# --------------------------------------------------------------------------------------------
# Warning! Running this file you accept that you know what you're doing. All actions with this
#          script are at your own risk.
# --------------------------------------------------------------------------------------------
# This Source Code Form is subject to the terms of the BSD 3-Clause License. If a copy of the
# source(s) distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

# Source mounted filesystem path, copy backups and subvolume creation path. All filesystems should be btrfs.
SOURCE_FILESYSTEM_PATH="/mnt/data/ssd/folder"
BACKUP_FILESYSTEM_PATH="/mnt/data/backup"
SNAPSHOTS_PATH="/mnt/data/ssd/.snapshots"

CURRENT_DATE=$(date +"%Y-%m-%d_%H-%M")
set -x
btrfs subvolume delete "${BACKUP_FILESYSTEM_PATH}/*" || true
btrfs subvolume snapshot -r "$SOURCE_FILESYSTEM_PATH" "${SNAPSHOTS_PATH}/@${CURRENT_DATE}"
sudo btrfs send "${SNAPSHOTS_PATH}/@${CURRENT_DATE}" | sudo btrfs receive "$BACKUP_FILESYSTEM_PATH"
btrfs subvolume delete "${SNAPSHOTS_PATH}/@${CURRENT_DATE}"
