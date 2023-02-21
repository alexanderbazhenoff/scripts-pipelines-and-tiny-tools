#!/usr/bin/env bash


# ----------------------------------------------------------------------------------- #
#                Clean expired volumes from Bareos storage pool script                #
# ----------------------------------------------------------------------------------- #
#
# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE
#
#
# Requirements:
#    * permissions to run 'bconsole' command and access to $poolpath
#      (don't mind if you run this script from bareos Admin Job, otherwise - you should
#      edit /etc/sudoers or run from root)
#    * git pacakge (apt or yum install git)
#    * shflags library: https://code.google.com/archive/p/shflags/
#      or: git clone https://github.com/kward/shflags.git
#
#
# Usage:
#    # ./clean_expired_baros_volumes.sh --name Full- --action delete --expire 10 --filter Pruned
# or
#   # ./clean_expired_baros_volumes.sh --help
#
# Use "--test yes" key for testmode (only output, no actions).
# For more information about volume status read Bareos manual:
#   * http://doc.bareos.org/master/html/bareos-manual-main-reference.html


# Logs file path
# Leave empty if you don't wish additional log file
LOGPATH=""

# Path of the pool
POOLPATH="/mnt/poolpath"


# Process volume function. In test mode prints only command (use for debug).
process_volume() {
  local F_NAME=$1
  local F_DATE=$2
  local MODE=$3
  echo "Processing: $F_NAME | $F_DATE"
  if [[ -n "$LOGPATH" ]]; then
    echo "Processing: $F_NAME | $F_DATE"
  fi

  if [[ $MODE == "no" ]]; then
    echo "$POOL_ACTION volume=$POOLPATH$F_NAME yes" | bconsole
    # Perform physical delete of file from $POOLPATH when "--action delete".
    # Doesn't matter if this volume is absent in bareos database, this will be removed.
    if [[ $POOL_ACTION = "delete" ]]; then
      echo "Perfomring physical delete of ${F_NAME} from ${POOLPATH}..."
      rm -f "$POOLPATH/$F_NAME" && echo "Removed." || echo "${F_NAME} not found."
    fi
  else
    echo "(test mode): echo \"$POOL_ACTION volume=$POOLPATH$F_NAME yes\" | bconsole"
  fi
}

print_usage_help() {
  echo "Error: unrecognized option(s): $POSITIONAL"
  echo ""
  echo "Usage:"
  echo ""
  echo "   -n | --pool-name"
  echo "          Pool name ('Full-', etc)."
  echo "   -a | --action [delete|purge|prune]"
  echo "          Action after expiration days."
  echo "   -e | --expiration"
  echo "          Filter by time expiration (days)."
  echo "   -f | --filter [none|Purged|Pruned]"
  echo "          Filter by status of volume."
  echo "   -d | --dry-run [yes|no]"
  exit 1
}


# entry point
POOL_NAME="Full-"
POOL_ACTION="delete"
POOL_EXPIRE='31'
POOL_FILTER='none'
DRY_RUN="no"

while [[ $# -gt 0 ]]; do
  KEY="$1"

  case $KEY in
  -n | --pool-name )
    POOL_NAME="$2"
    shift
    shift
    ;;
  -e | --expiration )
    POOL_EXPIRE="$2"
    shift
    shift
    ;;
  -f | --filter )
    POOL_FILTER="$2"
    shift
    shift
    ;;
  -d | --dry-run )
    DRY_RUN="$2"
    shift
    shift
    ;;
  *)                   # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
  esac
done

# error handling
if [[ $DRY_RUN != "no" ]] && [[ $SELECTION != "yes" ]]; then
  POSITIONAL+=("$SELECTION")
fi
for VALUE in "${POSITIONAL[@]}"
do
  echo "$VALUE"
  if [[ -n $VALUE ]]; then
    print_usage_help
  fi
done



echo "Performing ${POOL_ACTION} \"${POOL_NAME}\" volumes after ${POOL_EXPIRE} days,"
echo "filtered by \"${POOL_FILTER}\" status... Test mode: ${DRY_RUN}"
if [[ $POOL_ACTION = "delete" ]] || [[ $POOL_ACTION = "prune" ]] || [[ $POOL_ACTION = "purge" ]]; then
  cd $POOLPATH || exit 1
  filelist=$(find . -mtime +"$POOL_EXPIRE" -print | grep "$POOL_NAME" | sed 's/[./]//g')
  for FILENAME in $filelist
  do
    # shellcheck disable=SC2012
    FILEDATE=$(ls -lh "$FILENAME" | awk '{print $7" "$6" "$8}')
    if [[ $POOL_FILTER == "none" ]]; then
      echo "filter is none"
      process_volume "$FILENAME" "$FILEDATE" "$DRY_RUN"
    else
      # filter by volume status if $POOL_FILTER is not 'none'
      [[ -n $(echo "list volume" | bconsole | grep "$POOL_FILTER" | grep "$FILENAME" | cut -d ' ' -f6) ]] && \
        process_volume "$FILENAME" "$FILEDATE" "$DRY_RUN"
    fi
  done
else
  echo "Error! Uknown action: $POOL_ACTION"
  echo "Use \"prune\", \"purge\" or \"delete\"."
  exit 1
fi
