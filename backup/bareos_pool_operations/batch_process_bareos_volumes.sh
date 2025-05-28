#!/usr/bin/env bash

# Batch process range of Bareos volumes script.
# Copyright (c) 2018-2024, Aleksandr Bazhenov

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# ------------------------------------------------------------------------------------------
# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.
# ------------------------------------------------------------------------------------------

# Usage:
#
# ./batch_process_bareos_volumes.sh <action> <name_mask> <start> <end> <force/print> <pool_path_for_dumb>
#
# where: action should be 'prune', 'purge', 'delete' or 'dumb. Optional you can use: 'force'
#        to skip confirmation request or 'print' to get the info about selected range
#        of volumes. 'print' will not perform changes in volume status, just output an
#        info.
# e.g:
# ./batch_process_bareos_volumes.sh delete Incremental- 0032 1200
#
# when you set 'dumb' action <pool_name_for_dumb> <pool_path_for_dumb> may be specified, e.g.:
# /batch_process_bareos_volumes.sh delete Incremental- 0032 1200 /mnt/backup

usage() {
  cat <<EOF
Usage: $0 <action> <name_mask> <start> <end> <force|print> pool_name_for_dumb> <pool_path_for_dumb>
  action: prune | purge | delete | dumb
  For dumb action you can also specify pool path (e.g. '/mnt/backup'):
  $0 <action> <name_mask> <start> <end> <force|print> /mnt/backup
EOF
  exit 1
}

# Set up default pool path, e.g.: "/mnt/backup".
DEFAULT_POOL_PATH="/mnt/backup"

VOL_ACTION=$1
VOL_MASK=$2
VOL_START=$3
VOL_END=$4
VOL_OPT=$5
VOL_PATH=${6:-"$DEFAULT_POOL_PATH"}
USAGE_ERR=false

for var in VOL_ACTION VOL_MASK VOL_START VOL_END; do
  if [[ -z "${!var}" ]]; then
    echo "Error: '$var' is required."
    USAGE_ERR=true
  fi
done

[[ $VOL_ACTION =~ ^(prune|purge|delete|dumb)$ ]] || {
  echo "Error: invalid action specified."
  USAGE_ERR=true
}
[[ -z $VOL_OPT || $VOL_OPT =~ ^(force|print)$ ]] || {
  echo "Error: volume option should be empty, 'force' or 'print'."
  USAGE_ERR=true
}
[[ $VOL_START =~ ^[0-9]+$ ]] || {
  echo "Error: start volume is not a number"
  USAGE_ERR=true
}
[[ $VOL_END =~ ^[0-9]+$ ]] || {
  echo "Error: end volume is not a number"
  USAGE_ERR=true
}

if $USAGE_ERR; then
  usage
fi

echo "WARNING! This will process selected range of volumes in Bareos pool:"
echo "${VOL_ACTION} from ${VOL_START} to ${VOL_END} by mask ${VOL_MASK}"
read -p "Press Enter to proceed or Ctrl+C to abort..."

if [[ $VOL_ACTION == "dumb" ]]; then
  for RANGE_ITEM in $(seq -w "$VOL_START" "$VOL_END"); do
    RANGE_FILE="$VOL_MASK$RANGE_ITEM"
    echo "Creating an empty '$RANGE_FILE'..."
    touch "$VOL_PATH/$RANGE_FILE"
  done
else
  for RANGE_ITEM in $(eval "echo {$VOL_START..$VOL_END}"); do
    echo "${VOL_ACTION} volume: ${VOL_MASK}${RANGE_ITEM} $VOL_OPT"
    if [[ $VOL_OPT != 'print' ]]; then
      echo "${VOL_ACTION} volume=${VOL_MASK}${RANGE_ITEM} $([[ $VOL_OPT == 'force' ]] && echo 'yes')" | bconsole
    fi
  done
fi
