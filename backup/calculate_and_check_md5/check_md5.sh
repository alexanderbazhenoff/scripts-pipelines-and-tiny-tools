#!/usr/bin/env bash

# md5 checksum check for files in $SOURCE_PATH

# Copyright (c) 2021, Aleksandr Bazhenov

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

# ---------------------------------------------------------------------------
# Warning! Running this file you accept that you know what you're doing. All
# actions with this script are at your own risk.

ERROR_NOTIFICATION_SCRIPT_PATH="/opt/scripts/error_notification.sh"
SOURCE_PATH="/mnt/backup/"

usage_error() {
  cat <<EOF
Usage:
  -s|--source|--source-path /path/to/source/folder/or/file
                            (defaults: $SOURCE_PATH)
EOF
  exit 1
}

task_error() {
  if [[ $1 -ne 0 ]]; then
    echo "Sending $REMOTE_DRIVE_NAME error message"
    chrt -i 0 "$ERROR_NOTIFICATION_SCRIPT_PATH" "$2"
  fi
}

while [[ $# -gt 0 ]]; do
  KEY="$1"
  case $KEY in
  -s | --source | --source-path)
    SOURCE_PATH="$2"
    shift
    shift
    ;;
  *)
    usage_error
    ;;
  esac
done

echo "Ready to calculate md5 checksum on $(hostname) for directory: $SOURCE_PATH"
cd "$SOURCE_PATH" || { echo "Failed to change directory to $SOURCE_PATH" && exit 1; }

# List all “*.md5” files except “*.md5.md5” and alert error if none are found.
shopt -s nullglob extglob
set -- !(*.md5.md5).md5
(($#)) || "$ERROR_NOTIFICATION_SCRIPT_PATH" "no_md5_files_found!"

find . -type f -name '*.md5' ! -name '*.md5.md5' -exec bash -c \
  '[[ -f ${1//.md5} ]] && (md5sum -c ${1#./} || /./opt/scripts/check_error_notification.sh ${1#./})' -- {} \;
