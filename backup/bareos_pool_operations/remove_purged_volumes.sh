#!/usr/bin/env bash


# Remove all volumes physically from the disk which are in 'purged' state.
# Written by Aleksandr Bazhenov December, 2018. Updated December, 2021.

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

# ------------------------------------------------------------------------------
# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.


for F in $(echo "list volume" | bconsole | grep Purged | cut -d ' ' -f6)
do
  echo "delete volume=$F yes" | bconsole
  rm -rf /mnt/nas/"$F"
done

