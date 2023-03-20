#!/usr/bin/env bash


# -------------------------------------------------------------------------------- #
#     Physically delete non-existent volumes from Pool in the Bareos database.     #
#      Written by Alexander Bazhenov. December, 2018. Updated December, 2021.      #
# -------------------------------------------------------------------------------- #

# This Source Code Form is subject to the terms of the MIT License. If a copy of the
# MPL was not distributed with this file, You can obtain one at:
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
