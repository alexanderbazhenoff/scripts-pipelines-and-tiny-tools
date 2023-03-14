#!/usr/bin/env bash


### Backup, tar.gz and encrypt main script.
### Keep your files with rclone on remote storages/clouds.
###
### Reference:
### rclone: https://rclone.org/drive/
###         https://ostechnix.com/how-to-mount-google-drive-locally-as-virtual-file-system-in-linux/
###
### -----------------------------------------------------------------------------------------------
### Warning! Running this file you accept that you know what you're doing. All actions with this
###          script at your own risk.
### -----------------------------------------------------------------------------------------------
### This Source Code Form is subject to the terms of the MIT License. If a copy of the MPL was not
### distributed with this file, You can obtain one at:
### https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


# constants
BACKUP_DESTINATION="/mnt/backup_drive_path"
BACKUP_SCRIPT_PATH="/opt/scripts/backup_path_tar_gpg.sh"
ERROR_NOTIFICATION_SCRIPT_PATH="/opt/scripts/error_notification.sh"


usage_error() {
  echo "Error: unrecognized option(s): $POSITIONAL"
  echo ""
  echo "Usage:"
  echo "   -s|--source|--source-path /path/to/source/folder/or/file"
  echo "   -d|--destination|--destination-path /path/to/destination/folder"
  echo "   -p|--password |--password-file /path/to/password/file/name"
  echo "   -b|--backup"
  echo "   -r|--restore"
  echo "   --debug"
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

process_path(){
  local CURRENT_SOURCE_PATH=$1
  local CURRENT_DESTINATION_PATH=$2
  local CURRENT_ACTION=$3
  local CURRENT_FILENAME=$4
  local CURRENT_PASSWORD=$5
  local CURRENT_ENCRYPT_FLAG=$6
  local CURRENT_COMPRESS_FLAG=$7
  local CURRENT_CLEAN_DEST_FLAG=$8
  local CURRENT_EXCLUDE_LIST=$9
  if [[ $CURRENT_ACTION == "restore" ]]; then
    echo "Please note: $CURRENT_SOURCE_PATH and $CURRENT_DESTINATION_PATH will be swapped in restore mode"
    local TEMP_PATH=$CURRENT_SOURCE_PATH
    CURRENT_SOURCE_PATH=$CURRENT_DESTINATION_PATH
    CURRENT_DESTINATION_PATH=$TEMP_PATH
  fi
  if [[ -n $SOURCE_PATH ]]; then # override source path when this was set during script run
    CURRENT_SOURCE_PATH=$SOURCE_PATH
    echo "Source path override: $SOURCE_PATH"
  fi
  if [[ -n $DESTINATION_PATH ]]; then # override destination path when this was set during script run
    CURRENT_DESTINATION_PATH=$DESTINATION_PATH
    echo "Destination path override: $DESTINATION_PATH"
  fi
    local ARGS="-a $CURRENT_ACTION -s $CURRENT_SOURCE_PATH -d $CURRENT_DESTINATION_PATH "
    ARGS+="-f $CURRENT_FILENAME -p $CURRENT_PASSWORD "
  if [[ -n "$CURRENT_EXCLUDE_LIST" ]]; then
    ARGS+="-e $CURRENT_EXCLUDE_LIST "
  fi
  if $CURRENT_ENCRYPT_FLAG ; then
    ARGS+="--encrypt "
  fi
  if $CURRENT_COMPRESS_FLAG ; then
    ARGS+="--compress "
  fi
  if $CURRENT_CLEAN_DEST_FLAG ; then
    ARGS+="--clean-destination "
  fi
  if $DEBUG ; then
    ARGS+="--debug"
  fi
  # set your params for chrt command to change process priority.
  chrt -i 0 "/.$BACKUP_SCRIPT_PATH" $ARGS && return 0 || return 34
}

BACKUP_MODE=false
RESTORE_MODE=false
DEBUG=false
SOURCE_PATH=""
DESTINATION_PATH=""
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  KEY="$1"

  case $KEY in
  -s | --source | --source-path)
    SOURCE_PATH="$2"
    shift
    shift
    ;;
  -d | --destination | --destination-path)
    DESTINATION_PATH="$2"
    shift
    shift
    ;;
  -p | --password | --password-file)
    PASSWORD_FILE_PATH="$2"
    shift
    shift
    ;;
  -b | --backup)
    BACKUP_MODE=true
    shift
    ;;
  -r | --restore)
    RESTORE_MODE=true
    shift
    ;;
  --debug)
    DEBUG=true
    shift
    ;;


  *)                   # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

echo "SOURCE PATH (global)      = ${SOURCE_PATH}"
echo "DESTINATION PATH (global) = ${DESTINATION_PATH}"
echo "PASSWORD FILE PATH        = ${PASSWORD_FILE_PATH}"
echo "BACKUP MODE               = ${BACKUP_MODE}"
echo "RESTORE MODE              = ${RESTORE_MODE}"
echo "DEBUG                     = ${DEBUG}"
echo ""

# error handling
if $DEBUG ; then
  set -x
fi
if [[ -n $1 ]]; then
  echo "Error! Unknown option: $1"
  usage_error
fi

if $BACKUP_MODE && $RESTORE_MODE ; then
  echo "Error! Only one mode --backup or --restore should be specified."
  usage_error
fi

if ! $BACKUP_MODE && ! $RESTORE_MODE ; then
  echo "Action wasn't set. Nothing to do."
  usage_error
fi

if [[ -z $PASSWORD_FILE_PATH ]]; then
  echo "Error! Password path/file wasn't specified."
  usage_eror
fi

if [[ ! -f "$PASSWORD_FILE_PATH" ]]; then
  echo "Error! No password file found"
  exit 1
else
  PASSWORD=$(cat "$PASSWORD_FILE_PATH")
fi

if $BACKUP_MODE ; then
  ACTION="backup"
else
  ACTION="restore"
fi


# backup
sync; echo 3 > /proc/sys/vm/drop_caches; sync
sleep 5

# Backup all these scripts from /opt/script
process_path "/opt" "$BACKUP_DESTINATION" "$ACTION" \
"server3_scripts_$(date +%y%m%d).tar.gz" "$PASSWORD" false true true ""
task_error $? '/opt/scripts'

# Backup LXC container from /var/lib/lxc/lxc_container_name
process_path "/var/lib/lxc/bareos.emzior" "$BACKUP_DESTINATION" "$ACTION" \
"bareos_lxc_$(date +%y%m%d).tar.gz" "$PASSWORD" false true true "/opt/scripts/lxc_exclude"
echo $?; task_error $? '/var/lib/lxc/lxc_container_name'

sync; echo 3 > /proc/sys/vm/drop_caches; sync
