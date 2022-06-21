#!/usr/bin/env bash


# ---------------------------------------------------------------------------- #
#                Set all volumes in the pool to "purged" state                 #
# ---------------------------------------------------------------------------- #

# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at https://github.com/aws/mit-0

# Set your pool name here
POOL_NAME="Full"
PWD_R=$(pwd)
cd /var/lib/postgresql || exit 1
VOLUMES=$(sudo -u postgres -H -- psql -d bareos -c "SELECT volumename FROM media ORDER BY volumename" | tail -n+3 | \
	head -n -2 | grep $POOL_NAME)
cd "$PWD_R" || exit 1

echo "This will purge all volumes in $POOL_NAME. Sleep 30 for sure."
sleep 30

for VOL_ITEM in $VOLUMES
do
   echo "purge volume=$VOL_ITEM yes" | bconsole
done
