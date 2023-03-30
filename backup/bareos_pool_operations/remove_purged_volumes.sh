#!/usr/bin/env bash


# ---------------------------------------------------------------------------- #
#   Removes all volumes physically from the disk which are in 'purged' state   #
#     Written by Alexander Bazhenov December, 2018. Updated December, 2021.    #
# ---------------------------------------------------------------------------- #

# WARNING! Running this script may cause a potential data loss in your backup
# pools. All actions are at your own risk, otherwise you know what you're doing.

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source(s) distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


for F in $(echo "list volume" | bconsole | grep Purged | cut -d ' ' -f6)
do
  echo "delete volume=$F yes" | bconsole
  rm -rf /mnt/nas/"$F"
done

