#!/bin/bash

# ------------------------------------------------------------------------ #
# Removes all voluems physically from the disk which are in 'purged' state #
# ------------------------------------------------------------------------ #

for f in `echo "list volume" | bconsole | grep Purged | cut -d ' ' -f6`; do
  echo "delete volume=$f yes" | bconsole;
  rm -rf /mnt/nas/$f;
done

exit 0
