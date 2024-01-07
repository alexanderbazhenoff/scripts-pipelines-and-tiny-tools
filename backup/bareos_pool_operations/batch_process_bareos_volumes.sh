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


# Set up default pool path, e.g.: "/mnt/backup"
DEFAULT_POOL_PATH="/mnt/backup"


VOL_ACTION=$1
VOL_MASK=$2
VOL_START=$3
VOL_END=$4
VOL_OPT=$5
VOL_PATH=$6
OPTIONS_ERROR=0

[[ -z "$VOL_MASK" ]] && echo "Error! <name_mask> is undefined." && OPTIONS_ERROR=1
[[ -z "$VOL_ACTION" ]] && echo "Error! <action> is undefined." && OPTIONS_ERROR=1
[[ -z "$VOL_START" ]] && echo "Error! <start> is undefined." && OPTIONS_ERROR=1
[[ -z "$VOL_END" ]] && echo "Error! <end> is undefined." && OPTIONS_ERROR=1
[[ -z "$VOL_PATH" ]] && VOL_PATH=$DEFAULT_POOL_PATH

case $VOL_START in
	''|*[!0-9]*) echo "Error! <start> is not a number." && OPTIONS_ERROR=1
esac
case $VOL_END in
  ''|*[!0-9]*) echo "Error! <end> is not a number." && OPTIONS_ERROR=1
esac

if [[ -n "$VOL_OPT" ]] && [[ $VOL_OPT != "force" ]] && [[ $VOL_OPT != "print" ]]; then
  echo "Syntax error in additional options: $VOL_OPT" && OPTIONS_ERROR=1
fi


if [[ $VOL_ACTION != "prune" ]] && [[ $VOL_ACTION != "purge" ]] && [[ $VOL_ACTION != "delete" ]] && \
  [[ $VOL_ACTION != "dumb" ]]; then
	  echo "Syntax error in action option: $VOL_ACTION" && OPTIONS_ERROR=1
fi

if [[ $OPTIONS_ERROR -gt 0 ]]; then
  printf "Error: unrecognized option(s): %s" "$POSITIONAL"
	printf "Usage:\n\n"
  printf "%s %s\n" "# ./batch_process_bareos_volumes.sh <action> <name_mask> <start> <end> <force|print>" \
    "<pool_name_for_dumb> <pool_path_for_dumb>"
  printf "where action: prune|purge|delete|dumb.\n\n"
  printf "For dumb action you can also specify pool path (e.g. '/mnt/backup'):\n"
  printf "# ./batch_process_bareos_volumes.sh <action> <name_mask> <start> <end> <force|print> /mnt/backup\n"
	exit 1
fi

echo "WARNING! This will process selected range of volumes in Bareos pool:"
echo "${VOL_ACTION} from ${VOL_START} to ${VOL_END} by mask ${VOL_MASK}"
echo "Sleep 30 for sure."
sleep 30

if [[ $VOL_ACTION == "dumb" ]]; then
  for RANGE_ITEM in $(seq -w "$VOL_START" "$VOL_END")
    do
      RANGE_FILE="$VOL_MASK-$RANGE_ITEM"
      echo "Creating an empty '$RANGE_FILE'..."
      touch "$VOL_PATH/$RANGE_FILE"
    done
else
  for RANGE_ITEM in $(eval "echo {$VOL_START..$VOL_END}")
  do
    echo "${VOL_ACTION} volume: ${VOL_MASK}${RANGE_ITEM} $VOL_OPT"
    if [[ $VOL_OPT != 'print' ]]; then
      echo "${VOL_ACTION} volume=${VOL_MASK}${RANGE_ITEM} $([[ $VOL_OPT == 'force' ]] && echo 'yes')" | bconsole
    fi
  done
fi
