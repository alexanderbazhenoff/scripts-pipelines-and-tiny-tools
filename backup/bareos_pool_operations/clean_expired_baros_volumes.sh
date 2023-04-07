#!/usr/bin/env bash


# Clean expired volumes from Bareos storage pool script.
# Copyright (c) December, 2018. Aleksandr Bazhenov. Updated December, 2021.

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


# -------------------------------------------------------------------------------------
# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.
# -------------------------------------------------------------------------------------


# Requirements:
#    * permissions to run 'bconsole' command and access to $pool_path
#      (don't mind if you run this script from bareos Admin Job, otherwise - you should
#      edit /etc/sudoers or run from root)
#    * git pacakge (apt or yum install git)
#    * shflags library: https://code.google.com/archive/p/shflags/
#      or: git clone https://github.com/kward/shflags.git

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
LOG_PATH=""

# Path of the pool
POOL_PATH="/mnt/pool_path"


# Process volume function. In test mode prints only command (use for debug).
process_volume() {
  local F_NAME=$1
  local F_DATE=$2
  local MODE=$3
  echo "Processing: $F_NAME | $F_DATE"
  if [[ -n "$LOG_PATH" ]]; then
    echo "Processing: $F_NAME | $F_DATE"
  fi

  if [[ $MODE == "no" ]]; then
    echo "$POOL_ACTION volume=$POOL_PATH$F_NAME yes" | bconsole
    # Perform physical delete of file from $POOL_PATH when "--action delete".
    # Doesn't matter if this volume is absent in bareos database, this will be removed.
    if [[ $POOL_ACTION = "delete" ]]; then
      echo "Performing physical delete of ${F_NAME} from ${POOL_PATH}..."
      rm -f "$POOL_PATH/$F_NAME" && echo "Removed." || echo "${F_NAME} not found."
    fi
  else
    echo "(test mode): echo \"$POOL_ACTION volume=$POOL_PATH$F_NAME yes\" | bconsole"
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
  cd $POOL_PATH || exit 1
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
