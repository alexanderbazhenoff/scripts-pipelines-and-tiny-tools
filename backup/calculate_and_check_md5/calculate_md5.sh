#!/usr/bin/env bash

# md5 checksum calculation for $SOURCE_PATH

# Copyright (c) 2021, Aleksandr Bazhenov

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

# --------------------------------------------------------------------------
# Warning! Running this file you accept that you know what you're doing. All
# actions with this script are at your own risk.

SOURCE_PATH="/mnt/backup/"

usage_error() {
  cat <<EOF
Error: unrecognized option: $1

Usage:
  -s|--source|--source-path /path/to/source/folder/or/file
                            (defaults: $SOURCE_PATH)
EOF
  exit 1
}

check_md5() {
  echo "Checking existing ${1#./}'s md5..."
  if ! md5sum -c "$1.md5"; then
    echo "Re-calculating md5 for $1..."
    md5sum -b "$1" | tee "$1.md5"
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
    usage_error "$1"
    ;;
  esac
done

export -f check_md5

echo "Ready to calculate md5 checksum on $(hostname) for directory: $SOURCE_PATH"
find . ! -name '*.md5' -type f -exec bash -c \
  'if [[ -f $1.md5 ]]; then check_md5 $1; else md5sum -b $1 | tee $1.md5; fi' -- {} \; ||
  /./opt/scripts/check_error_notification.sh "md5" && exit 1
