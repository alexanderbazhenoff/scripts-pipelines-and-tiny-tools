#!/usr/bin/env bash


# Delete range of Bareos volumes.
# Copyright (c) December, 2018. Aleksandr Bazhenov. Updated December, 2021.

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

# ------------------------------------------------------------------------------
# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.


VOLUME_NAME="Full-"


echo "WARNING! This will remove selected range of volumes in pool."
echo "Sleep 10 for sure."
sleep 10

for I in {8702..8771}
do
  echo "Delete volume: ${VOLUME_NAME}${I}"
  echo "delete volume=${VOLUME_NAME}${I} yes" | bconsole
  sleep 1
done

