#!/usr/bin/env bash


# -------------------------------------------------------------------------------- #
#     Physically delete non-existent volumes from Pool in the Bareos database.     #
#      Written by Alexander Bazhenov. December, 2018. Updated December, 2021.      #
# -------------------------------------------------------------------------------- #

# WARNING! Running this script may cause a potential data loss in your backup
# pools. All actions are at your own risk, otherwise you know what you're doing.

# This Source Code Form is subject to the terms of the BSD 3-Clause License. If a copy of the
# source(s) distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


# Set Pool path
POOL_PATH=/mnt/pool_path

cd $POOL_PATH || exit
FILELIST=$(find . -maxdepth 1 -type f -printf "%f\n")
for I in $FILELIST; do
  echo "list volume=$I" | bconsole | if grep --quiet "No results to list"; then
    echo "$I is ready to be deleted"
    rm -f $POOL_PATH/"$I"
  fi
done
