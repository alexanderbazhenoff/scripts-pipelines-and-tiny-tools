#!/usr/bin/env bash

# Backup, tar.gz and encrypt main script.
# Keep your files with rclone on remote storages/clouds.
#
# Reference:
# rclone: https://rclone.org/drive/
#         https://ostechnix.com/how-to-mount-google-drive-locally-as-virtual-file-system-in-linux/

# Copyright (c) 2021, Aleksandr Bazhenov

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

# -----------------------------------------------------------------------------
# Warning! Running this file you accept that you know what you're doing. All
# actions with this script are at your own risk.

# Constants.
BACKUP_DESTINATION="/mnt/backup_drive_path"
BACKUP_SCRIPT_PATH="/opt/scripts/backup_path_tar_gpg.sh"
ERROR_NOTIFICATION_SCRIPT_PATH="/opt/scripts/error_notification.sh"

usage_error() {
  cat <<EOF >&2
Error: unrecognized option(s): $POSITIONAL

Usage:
  -s|--source|--source-path      /path/to/source/folder/or/file
  -d|--destination|--destination-path  /path/to/destination/folder
  -p|--password|--password-file  /path/to/password/file/name
  -b|--backup
  -r|--restore
  --debug
EOF
  exit 1
}

# If the given return code is non-zero, invoke the error notification script with the provided message.
# $1: return code to check;
# $2: error message to pass to notifier.
task_error() {
  if [[ $1 -ne 0 ]]; then
    echo "Sending $REMOTE_DRIVE_NAME error message"
    chrt -i 0 "$ERROR_NOTIFICATION_SCRIPT_PATH" "$2"
  fi
}

# Execute a chrt‐priority backup/restore command with encryption, compression and cleanup options.
# $1: source path;
# $2: destination path;
# $3: action (backup|restore);
# $4: output filename;
# $5: encryption password;
# $6: encrypt flag (true|false);
# $7: compress flag (true|false);
# $8: clean‐destination flag (true|false);
# $9: exclude‐list filepath (optional).
process_path() {
  local src=$1 dest=$2
  if [[ $3 == "restore" ]]; then
    echo "Please note: $1 and $2 will be swapped in restore mode"
    src=$2
    dest=$1
  fi

  # Override paths from global CLI options, if provided.
  if [[ -n "$SOURCE_PATH" ]]; then
    src="$SOURCE_PATH"
    echo "Source path override: $src"
  fi
  if [[ -n "$DESTINATION_PATH" ]]; then
    dest="$DESTINATION_PATH"
    echo "Destination path override: $dest"
  fi
  local -a args=(-a "$3" -s "$src" -d "$dest" -f "$4" -p "$5")
  [[ -n "$9" ]] && args+=(-e "$9")
  $6 && args+=(--encrypt)
  $7 && args+=(--compress)
  $8 && args+=(--clean-destination)
  $DEBUG && args+=(--debug)
  # Run the backup script with real-time priority.
  chrt -i 0 "/.$BACKUP_SCRIPT_PATH" "${args[@]}" && return 0 || return 34
}

flush_caches() {
  sync
  echo 3 >/proc/sys/vm/drop_caches
  sync
}

BACKUP_MODE=false
RESTORE_MODE=false
DEBUG=false
SOURCE_PATH=""
DESTINATION_PATH=""
PASSWORD_FILE_PATH=""

# Parse options via getopt.
PARSED=$(getopt -o s:d:p:br \
  -l source:,source-path:,destination:,destination-path:,password:,password-file:,backup,restore,debug -- "$@") ||
  usage_error
eval set -- "$PARSED"
while true; do
  case "$1" in
  -s | --source | --source-path)
    SOURCE_PATH="$2"
    shift 2
    ;;
  -d | --destination | --destination-path)
    DESTINATION_PATH="$2"
    shift 2
    ;;
  -p | --password | --password-file)
    PASSWORD_FILE_PATH="$2"
    shift 2
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
  --)
    shift
    break
    ;;
  *)
    usage_error
    ;;
  esac
done

for var in SOURCE_PATH DESTINATION_PATH PASSWORD_FILE_PATH BACKUP_MODE RESTORE_MODE DEBUG; do
  printf '%-20s = %s\n' "$var" "${!var}"
done

$DEBUG && set -x

if [[ -n $1 ]]; then
  echo "Error! Unknown option: $1"
  usage_error
fi

if $BACKUP_MODE && $RESTORE_MODE; then
  echo "Error! Only one mode --backup or --restore should be specified."
  usage_error
fi

if ! $BACKUP_MODE && ! $RESTORE_MODE; then
  echo "Action wasn't set. Nothing to do."
  usage_error
fi

if [[ -z $PASSWORD_FILE_PATH ]]; then
  echo "Error! Password path/file wasn't specified."
  usage_error
fi

if [[ ! -f "$PASSWORD_FILE_PATH" ]]; then
  echo "Error! No password file found"
  exit 1
else
  PASSWORD=$(cat "$PASSWORD_FILE_PATH")
fi

if $BACKUP_MODE; then
  ACTION="backup"
else
  ACTION="restore"
fi

flush_caches
sleep 5

# Backup all these scripts from /opt/script
process_path "/opt" "$BACKUP_DESTINATION" "$ACTION" \
  "server3_scripts_$(date +%y%m%d).tar.gz" "$PASSWORD" false true true ""
task_error $? '/opt/scripts'

# Backup LXC container from /var/lib/lxc/lxc_container_name
process_path "/var/lib/lxc/bareos.emzior" "$BACKUP_DESTINATION" "$ACTION" \
  "bareos_lxc_$(date +%y%m%d).tar.gz" "$PASSWORD" false true true "/opt/scripts/lxc_exclude"
task_error $? '/var/lib/lxc/lxc_container_name'

flush_caches
