#!/usr/bin/env bash

# ---------------------------------------------------------------------------- #
#     Physically delete non-existent volumes from Pool in the bareos database. #
# ---------------------------------------------------------------------------- #

# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at https://github.com/aws/mit-0

# Set Pool path
POOLPATH=/mnt/poolpath

cd $POOLPATH || exit
FILELIST=$(find . -maxdepth 1 -type f -printf "%f\n")
for I in $FILELIST; do
  echo "list volume=$I" | bconsole | if grep --quiet "No results to list"; then
    echo "$I is ready to be deleted"
    rm -f $POOLPATH/"$I"
  fi
done

