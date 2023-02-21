#!/usr/bin/env bash


# prune all volumes from pool (Bareos installation with MySQL)
# Written by Alexander Bazhenov. December, 2018. Updated December, 2021.
#
# This Source Code Form is subject to the terms of the MIT License. If a
# copy of the MPL was not distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


POOL_NAME="Incremental"
VOLUMES=$(mysql -u root -B -e'select VolumeName from Media order by VolumeName;' bareos | tail -n+2 | grep $POOL_NAME)

echo "This will prune all volumes in $POOL_NAME. Sleep 30 for sure."
sleep 30

for VOL_ITEM in $VOLUMES
do
  echo "prune volume=$VOL_ITEM yes" | bconsole
done
