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
  echo "Error: unrecognized option(s): $POSITIONAL"
  echo ""
  echo "Usage:"
  echo "   -a|--action backup|restore"
  echo "   -s|--source|--source-path /path/to/source/folder/or/file"
  echo "     (Remember that you should set /path/to/file in encrypt and no compression mode)"
  echo "   -d|--destination|--destination-path /path/to/destination/folder"
  echo "   -f|--filename some_filename"
  echo "   -p|--password some_password"
  echo "   -e|--excludelist /path/to/filename_of_list_to_exclude.txt"
  echo "   --encrypt"
  echo "   --compress"
  echo "   --clean-destination"
  echo "   --debug"
  exit 1
}

FILENAME=""
COMPRESS_EXCLUDE=""
ENCRYPT=false
COMPRESS=false
DEBUG=false
CLEAN_DESTINATION=false
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
  -a | --action)
    ACTION="$2"
    shift
    shift
    ;;
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
  -f | --filename)
    FILENAME="$2"
    shift
    shift
    ;;
  -p | --password)
    PASSWORD="$2"
    shift
    shift
    ;;
  -e | --excludelist)
    COMPRESS_EXCLUDE="--exclude-from=$2"
    shift
    shift
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

  *)                   # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
  esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ -z $SOURCE_PATH ]]; then
  SOURCE_PATH=$(pwd)
fi
if [[ -z $DESTINATION_PATH ]]; then
  DESTINATION_PATH=$(pwd)
fi

echo "DATE                 = $(date)"
echo "ACTION               = ${ACTION}"
echo "SOURCE PATH          = ${SOURCE_PATH}"
echo "DESTINATION PATH     = ${DESTINATION_PATH}"
echo "ENCRYPT              = ${ENCRYPT}"
echo "CLEAN DESTINATION    = ${CLEAN_DESTINATION}"
echo "COMPRESS             = ${COMPRESS}"
# shellcheck disable=SC2001
echo "PASSWORD             = $(echo $$PASSWORD | sed s/\./*/g)"

FULL_DESTINATION_PATH="${DESTINATION_PATH}/${FILENAME}"
FULL_SOURCE_PATH="${SOURCE_PATH}/${FILENAME}"
CURRENT_PATH=$(pwd)

echo "FILENAME             = ${FILENAME}"
echo "CURRENT PATH         = ${CURRENT_PATH}"
echo "COMPRESS EXTRA ARGS  = ${COMPRESS_EXCLUDE}"
echo ""

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
  usage_eror
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
  if $CLEAN_DESTINATION; then
    if [[ -f "$FULL_DESTINATION_PATH" ]]; then
      echo "Removing previous ${FULL_DESTINATION_PATH} file"
      rm -f "$FULL_DESTINATION_PATH"
    fi
  fi
  cd "$SOURCE_PATH" || exit 1
  tar "$COMPRESS_EXCLUDE" -czvf "$FULL_DESTINATION_PATH" . --numeric-owner
fi
if [[ $ACTION == "restore" ]] && $COMPRESS && ! $ENCRYPT; then
  if $CLEAN_DESTINATION; then
    echo "Unable to clean-up path $DESTINATION_PATH in '-a restore --compress' mode."
  fi
  cd "$DESTINATION_PATH" || exit 1
  tar --numeric-owner -xzvf "$FULL_SOURCE_PATH" --directory "$(pwd)"
fi

# backup or restore with compression and encryption
if $ENCRYPT && $COMPRESS; then
  if [[ $ACTION == "backup" ]]; then
    if $CLEAN_DESTINATION; then
      if [[ -f "$FULL_DESTINATION_PATH.enc" ]]; then
        echo "Removing previous ${FULL_DESTINATION_PATH}.enc file"
        rm -f "$FULL_DESTINATION_PATH".enc
      fi
    fi
    cd "$SOURCE_PATH" || exit 1
    tar "$COMPRESS_EXCLUDE" --numeric-owner -czvf - . | gpg2 --symmetric --batch --yes \
      --passphrase "$PASSWORD" --output "$FULL_DESTINATION_PATH".enc --yes --force-mdc
  fi
  if [[ $ACTION == "restore" ]]; then
    if $CLEAN_DESTINATION; then
      echo "Unable to clean-up path $DESTINATION_PATH in '-a restore --encrypt --compress' mode."
    fi
    cd "$DESTINATION_PATH" || exit 1
    echo "123"
    gpg2 --decrypt --batch --yes --passphrase "$PASSWORD" "$FULL_SOURCE_PATH".enc |
      tar --numeric-owner -xzvf -
  fi
fi

# backup or restore with encryption and no compression
if $ENCRYPT && ! $COMPRESS; then
  if [[ $ACTION == "backup" ]]; then
    if $CLEAN_DESTINATION; then
      if [[ -f "$FULL_DESTINATION_PATH.enc" ]]; then
        echo "Removing previous ${FULL_DESTINATION_PATH}.enc file"
        rm -f "$FULL_DESTINATION_PATH".enc
      fi
    fi
    cd "$SOURCE_PATH" || exit 1
    gpg2 --symmetric --batch --yes --passphrase "$PASSWORD" \
      --output "$FULL_DESTINATION_PATH".enc --force-mdc "$FILENAME"
    rm -f "$FULL_DESTINATION_PATH"
  fi
  if [[ $ACTION == "restore" ]]; then
    if $CLEAN_DESTINATION; then
      if [[ -f "$FULL_DESTINATION_PATH" ]]; then
        echo "Removing $FULL_DESTINATION_PATH file"
        rm -f "$FULL_DESTINATION_PATH"
      fi
    fi
    cd "$DESTINATION_PATH" || exit 1
    gpg2 --decrypt --batch --yes --passphrase "$PASSWORD" \
      --output "$FILENAME" "$FULL_SOURCE_PATH".enc
  fi
fi

cd "$CURRENT_PATH" || exit
