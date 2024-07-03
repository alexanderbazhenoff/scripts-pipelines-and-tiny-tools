#!/usr/bin/env bash

# Re-balance btrfs filesystem script
#
# This Source Code Form is subject to the terms of the BSD 3-Clause License. If a copy of the
# source(s) distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

for MOUNT_POINT in $(df -k -F btrfs | tail -n +2 | awk '{ print $6 }'); do
  printf "Starting re-balance of %s mount point...\n" "$MOUNT_POINT"
  FI_USAGE=$(sudo btrfs filesystem show "$MOUNT_POINT" | tail -n +3 | awk '{ print $6 }' | sed 's/[^[:digit:].]//g')
  for i in $(seq 5 10 95); do
    printf "Performing btrfs re-balance with -dusage=%s... " "$i"
    # Chunks utilized up to $i percents can be relocated to other chunks while still freeing the space, otherwise
    # quite the loop.
    set +e
    sudo btrfs balance start -dusage="$i" --full-balance "$MOUNT_POINT" ||
      {
        printf "Unable to re-balance. Stopping.\n"
        break
      }
    CURRENT_FI_USAGE=$(sudo btrfs filesystem show "$MOUNT_POINT" | tail -n +3 | awk '{ print $6 }' |
      sed 's/[^[:digit:].]//g')
    if (($(echo "$CURRENT_FI_USAGE >= $FI_USAGE" | bc -l))); then
      printf "No results. "
    else
      printf "Optimized. "
    fi
    FI_USAGE=$CURRENT_FI_USAGE
    printf "Usage size is %s.\n" "$(sudo btrfs filesystem show "$MOUNT_POINT" | tail -n +3 | awk '{ print $6 }')"
  done
done
