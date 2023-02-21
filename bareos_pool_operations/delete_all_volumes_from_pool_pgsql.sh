#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at:
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
