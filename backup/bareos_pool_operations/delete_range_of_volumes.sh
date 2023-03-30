#!/usr/bin/env bash


# Written by Alexander Bazhenov December, 2018. Updated December, 2021.

# WARNING! Running this script may cause a potential data loss in your backup
# pools. All actions are at your own risk, otherwise you know what you're doing.

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source(s) distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


echo "WARNING! This will remove selected range of volumes in pool."
echo "Sleep 10 for sure."
sleep 10
VOLUME_NAME="Full-"

for I in {8702..8771}
do
  echo "Delete volume: ${VOLUME_NAME}${I}"
  echo "delete volume=${VOLUME_NAME}${I} yes" | bconsole
  sleep 1
done

