#!/usr/bin/env bash


# ---------------------------------------------------------------------------- #
#                Set all volumes in the pool to "purged" state                 #
# ---------------------------------------------------------------------------- #

# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at https://github.com/aws/mit-0


# Set your pool name here
POOL_NAME="Incremental"

VOLUMES=$(mysql -u root -B -e'select VolumeName from Media order by VolumeName;' bareos | tail -n+2 | grep $POOL_NAME)

echo "This will purge all volumes in $POOL_NAME. Sleep 30 for sure."
sleep 30

for VOL_ITEM in $VOLUMES
do
   echo "purge volume=$VOL_ITEM yes" | bconsole
done
