#!/usr/bin/env bash


### md5 checksum check for files in $SOURCE_PATH
###
### -----------------------------------------------------------------------------------------------
### Warning! Running this file you accept that you know what you're doing. All actions with this
###          script at your own risk.
### -----------------------------------------------------------------------------------------------
### This Source Code Form is subject to the terms of the MIT License. If a copy of the MPL was not
### distributed with this file, You can obtain one at:
### https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


ERROR_NOTIFICATION_SCRIPT_PATH="/opt/scripts/error_notification.sh"
SOURCE_PATH="/mnt/backup/"

usage_error() {
  echo ""
  echo "Usage:"
  echo "   -s|--source|--source-path /path/to/source/folder/or/file"
  echo "                             (defaults: $SOURCE_PATH)"
  exit 1
}

task_error(){
  local RETURN_CODE=$1
  local ERROR_MESSAGE=$2
  if [[ $RETURN_CODE -ne 0 ]]; then
    echo "Sending $REMOTE_DRIVE_NAME error message"
    chrt -i 0 /.$ERROR_NOTIFICATION_SCRIPT_PATH "$ERROR_MESSAGE"
  fi
}

while [[ $# -gt 0 ]]; do
  KEY="$1"

  case $KEY in
  -s | --source | --source-path)
    SOURCE_PATH="$2"
    shift
    shift
    ;;

  *)                   # unknown option
    POSITIONAL+=("$1")
    shift
    ;;
  esac
done

set -- "${POSITIONAL[@]}"

HOSTNAME="$(hostname)"
echo "Ready to calculate md5 checksum on $HOSTNAME for directory: $SOURCE_PATH"
cd "$SOURCE_PATH" || exit 1

if [[ -z $(ls -1 | grep '.md5' | grep -v "md5.md5") ]]; then
   /./opt/scripts/check_error_notification.sh "no_md5_files_found!"
fi

find . -type f -name '*.md5' ! -name '*.md5.md5' -exec bash -c \
  '[[ -f ${1//.md5} ]] && (md5sum -c ${1#./} || /./opt/scripts/check_error_notification.sh ${1#./})' -- {} \;
