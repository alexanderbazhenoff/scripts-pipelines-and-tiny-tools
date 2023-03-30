#!/usr/bin/env bash


# Written by Alexander Bazhenov December, 2018. Updated December, 2021.

# WARNING! Running this script may cause a potential data loss in your backup
# pools. All actions are at your own risk, otherwise you know what you're doing.

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source(s) distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


POOL_NAME="Incremental-"
PWD_R=$(pwd)
cd /var/lib/postgresql || exit 1
VOLUMES=$(sudo -u postgres -H -- psql -d bareos -c "SELECT volumename FROM media ORDER BY volumename" | tail -n+3 | \
	head -n -2 | grep $POOL_NAME)
cd "$PWD_R" || exit 1

echo "This will delete all volumes in ${POOL_NAME}. Sleep 10 for sure."
sleep 10

for vol in $VOLUMES
do
  echo "delete volume=${vol} yes" | bconsole
done
