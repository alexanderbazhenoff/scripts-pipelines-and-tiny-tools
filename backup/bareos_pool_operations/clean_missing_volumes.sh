#!/usr/bin/env bash


# Physically delete non-existent volumes from Pool in the Bareos database.
# Copyright (c) 2018-2024, Aleksandr Bazhenov.

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-and-tools/blob/master/LICENSE

# ------------------------------------------------------------------------------
# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.


# Set Pool path, e.g.: /mnt/pool_path
POOL_PATH="/mnt/backup"


cd $POOL_PATH || exit 1
FILELIST=$(find . -maxdepth 1 -type f -printf "%f\n")
[[ -z $FILELIST ]] && echo "Nothing to process."
for I in $FILELIST; do
  echo "list volume=$I" | bconsole | if grep --quiet "No results to list"; then
    echo "$I is ready to be deleted"
    rm -f $POOL_PATH/"$I"
  fi
done
