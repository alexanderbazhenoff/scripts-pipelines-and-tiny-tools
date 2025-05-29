#!/usr/bin/env bash

# Clean expired volumes from Bareos storage pool script.
# Copyright (c) 2018-2024, Aleksandr Bazhenov.

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
#      (don't mind if you run this script from Bareos Admin Job, otherwise - you should
#      edit /etc/sudoers or run from root)

# Usage:
#    # ./clean_expired_bareos_volumes.sh --name Full- --action delete --expire 10 --filter Pruned
# or
#   # ./clean_expired_bareos_volumes.sh --help
#
# Use "--test yes" key for test mode (only output, no actions).
# For more information about volume status read Bareos manual:
#   * http://doc.bareos.org/master/html/bareos-manual-main-reference.html

# Logs file path
# Leave empty if you don't wish additional log file
LOG_PATH=""

# Path of the pool, e.g.: /mnt/pool_path
POOL_PATH="/mnt/backup"

# Logging function: prints timestamp and level; exits on ERROR.
log() {
  local level=$1 message=$2
  printf '%s [%s] %s\n' "$(date +'%Y-%m-%dT%H:%M:%S')" "$level" "$message" | tee -a "${LOG_PATH:-/dev/null}"
  [[ $level == "ERROR" ]] && exit 1
}

# Process volume function. In test mode prints only command (use for debug).
process_volume() {
  local file=$1
  log INFO "Processing: $file | $2"
  if [[ $3 == "no" ]]; then
    echo "$POOL_ACTION volume=${POOL_PATH}${file} yes" | bconsole
    # Perform physical delete of file from $POOL_PATH when "--action delete".
    # Doesn't matter if this volume is absent in Bareos database, this will be removed.
    if [[ $POOL_ACTION = "delete" ]]; then
      log INFO "Performing physical delete of ${file} from ${POOL_PATH}..."
      rm -f "$POOL_PATH/$file" && echo "Removed." || echo "${file} not found."
    fi
  else
    echo "(test mode): echo \"$POOL_ACTION volume=${POOL_PATH}${file} yes\" | bconsole"
  fi
}

print_usage_help() {
  if [[ $# -gt 0 ]]; then
    echo "Error: unrecognized option(s): $*"
  fi
  cat <<EOF

Usage:
  -n, --name     Pool name ('Full-', etc)
  -a, --action   Action after expiration: delete|purge|prune
  -e, --expire   Expiration in days (integer)
  -f, --filter   Filter by status: none|Purged|Pruned
  -d, --dry-run  Dry-run mode: yes|no
  -h, --help     Show this help
EOF
  if [[ $# -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

# Entry point.
set -euo pipefail
IFS=$'\n\t'

POOL_NAME="Full-"
POOL_ACTION="delete"
POOL_EXPIRE='31'
POOL_FILTER='none'
DRY_RUN="no"

OPTIND=1
while getopts ":n:a:e:f:d:h-:" opt; do
  case "$opt" in
  n) POOL_NAME=$OPTARG ;;
  a) POOL_ACTION=$OPTARG ;;
  e) POOL_EXPIRE=$OPTARG ;;
  f) POOL_FILTER=$OPTARG ;;
  d) DRY_RUN=$OPTARG ;;
  h) print_usage_help ;;
  -)
    case "$OPTARG" in
    help)
      print_usage_help
      ;;
    name)
      POOL_NAME="${!OPTIND}"
      OPTIND=$((OPTIND + 1))
      ;;
    action)
      POOL_ACTION="${!OPTIND}"
      OPTIND=$((OPTIND + 1))
      ;;
    expire)
      POOL_EXPIRE="${!OPTIND}"
      OPTIND=$((OPTIND + 1))
      ;;
    filter)
      POOL_FILTER="${!OPTIND}"
      OPTIND=$((OPTIND + 1))
      ;;
    dry-run)
      DRY_RUN="${!OPTIND}"
      OPTIND=$((OPTIND + 1))
      ;;
    *)
      print_usage_help "$OPTARG"
      ;;
    esac
    ;;
  *) print_usage_help ;;
  esac
done
shift $((OPTIND - 1))

# Check for any leftover arguments.
if [[ $# -gt 0 ]]; then
  log ERROR "Unknown parameters: $*"
fi
# Check for wrong parameters.
[[ $DRY_RUN =~ ^(yes|no)$ ]] || log ERROR "Wrong dry-run options, should be 'yes' or 'no'."
[[ $POOL_ACTION =~ ^(delete|prune|purge)$ ]] || log ERROR "Wrong pool action, should be 'delete', 'prune' or 'purge'."

log INFO "Performing '${POOL_ACTION}' '${POOL_NAME}' volumes after ${POOL_EXPIRE} days, filtered by '${POOL_FILTER}' \
status... Test mode: '${DRY_RUN}'."
cd "$POOL_PATH" || log ERROR "Cannot cd to $POOL_PATH"
FILE_LIST=$(find . -maxdepth 1 -type f -mtime +"$POOL_EXPIRE" -printf '%f\n' | grep -F "$POOL_NAME")

if [[ -z $FILE_LIST ]]; then
  log WARNING "No expired volumes in '$POOL_NAME' pool by specified criteria ($POOL_EXPIRE days), nothing to \
'$POOL_ACTION'."
else
  for FILENAME in $FILE_LIST; do
    FILE_DATE="$(stat --printf='%y' "$FILENAME")"
    if [[ $POOL_FILTER == "none" ]]; then
      process_volume "$FILENAME" "$FILE_DATE" "$DRY_RUN"
    else
      # Filter by volume status if $POOL_FILTER is set.
      [[ -n $(echo "list volume" | bconsole | grep "$POOL_FILTER" | grep "$FILENAME" | cut -d ' ' -f6) ]] &&
        process_volume "$FILENAME" "$FILE_DATE" "$DRY_RUN"
    fi
  done
fi
