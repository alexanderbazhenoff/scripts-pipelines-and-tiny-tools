#!/usr/bin/env bash


# ----------------------------------------------------------------------------------------- #
#                        Batch process range of Bareos volumes script                       #
# ----------------------------------------------------------------------------------------- #

# WARNING! Running this script may cause a potential data loss in your backup
# pools. All actions are at your own risk, otherwise you know what you're doing.


# This Source Code Form is subject to the terms of the BSD 3-Clause License. If a copy of the
# source(s) distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE

# Usage:
#
#        # batch_process_bareos_volumes.sh <action> <name_mask> <start> <end> <--force/print>
#
#   where: action should be 'prune', 'purge' or 'delete'. Optional you can use: '--force'
#          to skip confirmation request or '--print' to get the info about selected range
#          of volumes. '--print' will not perform changes in volume status, just output an
#          info.
#   e.g:
#        # batch_process_bareos_volumes.sh delete Incremental- 0032 1200


VOL_ACTION=$1
VOL_MASK=$2
VOL_START=$3
VOL_END=$4
VOL_OPT=$5
OPTIONS_ERROR=0

[[ -z "$VOL_MASK" ]] && echo "Error! <name_mask> is undefined." && OPTIONS_ERROR=1
[[ -z "$VOL_ACTION" ]] && echo "Error! <action> is undefined." && OPTIONS_ERROR=1
[[ -z "$VOL_START" ]] && echo "Error! <start> is undefined." && OPTIONS_ERROR=1
[[ -z "$VOL_END" ]] && echo "Error! <end> is undefined." && OPTIONS_ERROR=1

case $VOL_START in
	''|*[!0-9]*) echo "Error! <start> is not a number." && OPTIONS_ERROR=1
esac
case $VOL_END in
  ''|*[!0-9]*) echo "Error! <end> is not a number." && OPTIONS_ERROR=1
esac

if [[ -n "$VOL_OPT" ]]; then
	if [[ $VOL_OPT != "force" ]] && [[ $VOL_OPT != "print" ]]; then
		echo "Syntax error in additional options: $VOL_OPT" && OPTIONS_ERROR=1
	fi
fi

if [[ $VOL_ACTION != "prune" ]] && [[ $VOL_ACTION != "purge" ]] && [[ $VOL_ACTION != "delete" ]]; then
	echo "Syntax error in action option: $VOL_ACTION" && OPTIONS_ERROR=1
fi

if [[ $OPTIONS_ERROR -gt 0 ]]; then
	echo "Usage:"
  echo "# ./batch_process_bareos_volumes.sh <action> <name_mask> <start> <end> <force|print>"
	exit 1
fi

echo "WARNING! This will process selected range of volumes in Bareos pool:"
echo "${VOL_ACTION} from ${VOL_START} to ${VOL_END} by mask ${VOL_MASK}"
echo "Sleep 30 for sure."
sleep 30

for RANGE_ITEM in $(eval "echo {$VOL_START..$VOL_END}")
do
  echo "${VOL_ACTION} volume: ${VOL_MASK}${RANGE_ITEM} $VOL_OPT"
  if [[ $VOL_OPT != 'print' ]]; then
    echo "${VOL_ACTION} volume=${VOL_MASK}${RANGE_ITEM} $([[ $VOL_OPT == 'force' ]] && echo 'yes')" | bconsole
  fi
done
