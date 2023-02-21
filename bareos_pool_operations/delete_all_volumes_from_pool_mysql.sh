#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE

POOL_NAME="Full"
VOLUMES=$(mysql -u root -B -e'select VolumeName from Media order by VolumeName;' bareos | tail -n+2 | grep $POOL_NAME)

echo "This will delete all volumes in ${POOL_NAME}. Sleep 10 for sure."
sleep 10

for VOL_ITEM in $VOLUMES
do
  echo "delete volume=${VOL_ITEM} yes" | bconsole
done
