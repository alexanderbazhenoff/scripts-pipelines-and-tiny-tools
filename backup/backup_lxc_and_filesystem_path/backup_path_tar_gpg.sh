#!/usr/bin/env bash

# Backup and restore script for files, folders and lxc containers
# with tar.gz and gpg2 encryption.
#
# Reference:
# - lxc backup: https://stackoverflow.com/questions/23427129/how-do-i-backup-move-lxc-containers
# - gpg: https://backreference.org/2014/08/15/file-encryption-on-the-command-line/

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

usage_error() {
  cat <<EOF >&2
Error: unrecognized option(s): $POSITIONAL

Usage:
  -a|--action backup|restore
  -s|--source|--source-path /path/to/source/folder/or/file
    (Remember that you should set /path/to/file in encrypt and no compression mode)
  -d|--destination|--destination-path /path/to/destination/folder
  -f|--filename some_filename
  -p|--password some_password
  -e|--exclude-list /path/to/filename_of_list_to_exclude.txt
  --encrypt
  --compress
  --clean-destination
  --debug
EOF
  exit 1
}

clean_destination() {
  $CLEAN_DESTINATION && (
    echo "Removing previous $1 file"
    rm -f "$1"
  )
}

FILENAME=""
COMPRESS_EXCLUDE=""
ENCRYPT=false
COMPRESS=false
DEBUG=false
CLEAN_DESTINATION=false

PARSED=$(getopt -o a:s:d:f:p:e: \
  -l action:,source-path:,destination-path:,filename:,password:,exclude-list:,encrypt,compress,clean-destination,debug \
  -- "$@") || usage_error
eval set -- "$PARSED"
while true; do
  case "$1" in
  -a | --action)
    ACTION="$2"
    shift 2
    ;;
  -s | --source | --source-path)
    SOURCE_PATH="$2"
    shift 2
    ;;
  -d | --destination | --destination-path)
    DESTINATION_PATH="$2"
    shift 2
    ;;
  -f | --filename)
    FILENAME="$2"
    shift 2
    ;;
  -p | --password)
    PASSWORD="$2"
    shift 2
    ;;
  -e | --exclude-list)
    COMPRESS_EXCLUDE="--exclude-from=$2"
    shift 2
    ;;
  --encrypt)
    ENCRYPT=true
    shift
    ;;
  --compress)
    COMPRESS=true
    shift
    ;;
  --clean-destination)
    CLEAN_DESTINATION=true
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
  *) usage_error ;;
  esac
done

FULL_SOURCE_PATH="${SOURCE_PATH:-"$(pwd)/$FILENAME"}"
FULL_DESTINATION_PATH="${DESTINATION_PATH:-"$(pwd)/$FILENAME"}"

for v in ACTION FILENAME COMPRESS_EXCLUDE ENCRYPT COMPRESS CLEAN_DESTINATION DEBUG; do
  printf '%-20s %s\n' "$v" "${!v}"
done
printf '%-20s %s\n' SOURCE_PATH "$(dirname "$FULL_SOURCE_PATH")"
printf '%-20s %s\n' DESTINATION_PATH "$(dirname "$FULL_DESTINATION_PATH")"
printf '%-20s %s\n' PASSWORD "$(echo "$PASSWORD" | sed s/\./*/g)"

# error handling
if [[ -n $1 ]]; then
  echo "Error! Unknown option: $1"
  usage_error
fi

if [[ -z $ACTION ]] || [[ $ACTION != "backup" && $ACTION != "restore" ]]; then
  echo "Error! Unknown or empty action specified."
  usage_error
fi

if [[ -z $FILENAME ]]; then
  echo "Error! Filename wasn't specified."
  usage_error
fi

if [[ $ENCRYPT && -z $PASSWORD ]]; then
  echo "Error! No password specified for encryption."
  usage_error
fi

if $DEBUG; then
  set -x
fi

# create dir and process
if [[ ! -d "$DESTINATION_PATH" ]]; then
  echo "No ${DESTINATION_PATH} found, creating..."
  mkdir -p "$DESTINATION_PATH"
fi

set -e

# backup or restore with compression and no encryption
if [[ $ACTION == "backup" ]] && $COMPRESS && ! $ENCRYPT; then
  clean_destination "$FULL_DESTINATION_PATH"
  tar "$COMPRESS_EXCLUDE" --numeric-owner -C "$(dirname "$FULL_SOURCE_PATH")" -czvf "$FULL_DESTINATION_PATH" .
fi
if [[ $ACTION == "restore" ]] && $COMPRESS && ! $ENCRYPT; then
  if $CLEAN_DESTINATION; then
    echo "Unable to clean-up path $DESTINATION_PATH in '-a restore --compress' mode."
  fi
  tar --numeric-owner -C "$(dirname "$FULL_DESTINATION_PATH")" -xzvf "$FULL_SOURCE_PATH"
fi

# backup or restore with compression and encryption
if $ENCRYPT && $COMPRESS; then
  if [[ $ACTION == "backup" ]]; then
    clean_destination "$FULL_DESTINATION_PATH".enc
    tar "$COMPRESS_EXCLUDE" --numeric-owner -C "$(dirname "$FULL_SOURCE_PATH")" -czvf - . | gpg2 --symmetric --batch \
      --yes --passphrase "$PASSWORD" --output "$FULL_DESTINATION_PATH".enc --force-mdc
  fi
  if [[ $ACTION == "restore" ]]; then
    if $CLEAN_DESTINATION; then
      echo "Unable to clean-up path $DESTINATION_PATH in '-a restore --encrypt --compress' mode."
    fi
    gpg2 --decrypt --batch --yes --passphrase "$PASSWORD" "$FULL_SOURCE_PATH".enc |
      tar --numeric-owner -C "$(dirname "$FULL_DESTINATION_PATH")" -xzvf -
  fi
fi

# backup or restore with encryption and no compression
if $ENCRYPT && ! $COMPRESS; then
  if [[ $ACTION == "backup" ]]; then
    clean_destination "$FULL_DESTINATION_PATH".enc
    gpg2 --symmetric --batch --yes --passphrase "$PASSWORD" --output "$FULL_DESTINATION_PATH".enc --force-mdc \
      "$FULL_SOURCE_PATH"
    rm -f "$FULL_DESTINATION_PATH"
  fi
  if [[ $ACTION == "restore" ]]; then
    clean_destination "$FULL_DESTINATION_PATH"
    gpg2 --decrypt --batch --yes --passphrase "$PASSWORD" --output "$FULL_DESTINATION_PATH" "$FULL_SOURCE_PATH".enc
  fi
fi
