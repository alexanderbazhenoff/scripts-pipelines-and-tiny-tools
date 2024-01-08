#!/usr/bin/env bash


# Set all volumes in the pool to "purged" state (Bareos PostgreSQL installation).
# Copyright (c) 2018-2024. Aleksandr Bazhenov.

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-and-tools/blob/master/LICENSE

# ------------------------------------------------------------------------------
# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.


# Set pool name, e.g.: "Incremental" or "Full"
POOL_NAME="Full"

PWD_R=$(pwd)
cd /var/lib/postgresql || exit 1
VOLUMES=$(sudo -u postgres -H -- psql -d bareos -c "SELECT volumename FROM media ORDER BY volumename" | tail -n+3 | \
	head -n -2 | grep $POOL_NAME)
[[ -z $VOLUMES ]] && echo "No volumes in the pool, nothing to do." && exit
cd "$PWD_R" || exit 1

echo "This will purge all volumes in $POOL_NAME. Sleep 30 for sure."
sleep 30

for VOL_ITEM in $VOLUMES
do
   echo "purge volume=$VOL_ITEM yes" | bconsole
done
