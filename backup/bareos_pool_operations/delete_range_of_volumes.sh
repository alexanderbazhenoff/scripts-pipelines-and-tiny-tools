#!/usr/bin/env bash


# Written by Alexander Bazhenov December, 2018. Updated December, 2021.
# This Source Code Form is subject to the terms of the MIT License. If a
# copy of the MPL was not distributed with this file, You can obtain one at:
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

