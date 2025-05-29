#!/usr/bin/env bash

# Backup script for KVM virtual machines.

# Copyright (c) July 2018, Aleksandr Bazhenov.

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

# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.

# specify backup folder here:
BACKUP_DIR="/var/lib/libvirt/images/backup"

# specify log file path here:
LOGFILE="/var/log/kvm_backup.log"

fatal() { echo "Error: $*" >&2 && exit 1; }

usage() {
  cat <<EOF
Usage: $0 [--active|--stopped|--clean] <vm1 vm2 ...>

  --active           Create backup of running VM(s). Required
                     qemu-guest-agent installed on virtual machine
                     and qemu-channel device created
  --stopped          Stop, create backup and run virtual machine
  --clean            Clean previous backups from backup folder

Examples:
  $0 --active vm_name1 vm_name2
  $0 --clean vm_name1 vm_name2
EOF
  exit 1
}

init_log() {
  ((LOG_INITIALIZED)) && return
  mkdir -p "$(dirname "$LOGFILE")"
  exec >> >(tee -a "$LOGFILE") 2>&1
  LOG_INITIALIZED=1
}

start_log() {
  mkdir -p "$BACKUP_DIR/$ACTIVEVM"
  echo "$(date +'%Y-%m-%d %H:%M:%S') Starting backup of $ACTIVEVM"
}
# backup config of VM.
backup_vm_config() {
  virsh dumpxml "$ACTIVEVM" >"$BACKUP_DIR/$ACTIVEVM/$ACTIVEVM".xml
  echo "$(date '+%Y-%m-%d %H:%M:%S') Saved $ACTIVEVM domain XML"
}

# double‑checks the path we are about to delete.
safe_rm() {
  local target="$1"
  [[ -z "$target" || "$target" == "/" ]] && fatal "Refusing to remove empty or root path"
  [[ ! -e "$target" ]] && fatal "safe_rm: '$target' does not exist"
  rm -rf --one-file-system -- "$target"
}

# Getting a list and a path of disk images.
vm_disks_get() {
  # robust domblklist parsing using separator
  mapfile -t DISK_INFO < <(virsh domblklist --details --type disk --noheadings --separator '|' "$ACTIVEVM" 2>/dev/null)
  DISK_LIST=()
  DISK_PATH=()
  for line in "${DISK_INFO[@]}"; do
    IFS='|' read -r target source _type _dev <<<"$line"
    DISK_LIST+=("$target")
    DISK_PATH+=("$source")
  done
  echo "$(date '+%Y-%m-%d %H:%M:%S') Disk targets: ${DISK_LIST[*]}"
  echo "$(date '+%Y-%m-%d %H:%M:%S') Disk paths  : ${DISK_PATH[*]}"
}

# Getting a block device which is a snapshot.
get_snapshots() {
  virsh snapshot-list --domain "$ACTIVEVM" --no-metadata --name 2>/dev/null || true
}

# Entry point.
set -euo pipefail
IFS=$'\n\t'
shopt -s nocasematch

[[ $# -lt 2 ]] && usage
COMMAND_USE="$1"
shift

[[ $EUID -ne 0 ]] && fatal "Please run as root (e.g. sudo $0 ...)"

case "$COMMAND_USE" in
--active | --stopped | --clean) ;;
*) usage ;;
esac

LOG_INITIALIZED=0
init_log

for ACTIVEVM in "$@"; do
  SNAPSHOT_NAME="snapshot-${ACTIVEVM}-$(date +%s%N)"
  start_log
  backup_vm_config
  vm_disks_get

  if [[ $COMMAND_USE == "--active" ]]; then
    echo "Creating live snapshot $SNAPSHOT_NAME for $ACTIVEVM"
    if ! get_snapshots | grep -Fxq "$SNAPSHOT_NAME"; then
      virsh snapshot-create-as --domain "$ACTIVEVM" "$SNAPSHOT_NAME" --disk-only \
        --atomic --quiesce --no-metadata
    else
      echo "Snapshot $SNAPSHOT_NAME already exists – skipping create"
    fi

    # refresh disk list after snapshot so we copy the backing image layer
    vm_disks_get

    for SRC in "${DISK_PATH[@]}"; do
      FILENAME=$(basename "$SRC")
      [[ "$SRC" == "-" || "$SRC" == *.iso ]] && { echo "Skip removable/media: $SRC" && continue; }
      echo "Copying $SRC -> $BACKUP_DIR/$ACTIVEVM/$FILENAME"
      cp --reflink=auto --sparse=always "$SRC" "$BACKUP_DIR/$ACTIVEVM/$FILENAME"
    done

    # commit + remove snapshot layer
    for disk in "${DISK_LIST[@]}"; do
      virsh blockcommit "$ACTIVEVM" "$disk" --active --verbose --pivot || echo "Nothing to commit for $disk"
    done
    vm_disks_get
    # remove snapshot file(s)
    for p in "${DISK_PATH[@]}"; do
      [[ $p == *.snapshot ]] || continue
      echo "Removing leftover snapshot layer $p"
      rm -f -- "$p"
    done
    echo "Backup of $ACTIVEVM finished"

  elif [[ $COMMAND_USE == "--stopped" ]]; then
    echo "Shutting down $ACTIVEVM"
    virsh shutdown "$ACTIVEVM" || true
    COUNTER=40 # 40*3=120s
    while virsh list --name | grep -Fxq "$ACTIVEVM" && ((COUNTER-- > 0)); do
      sleep 3
    done
    if virsh list --name | grep -Fxq "$ACTIVEVM"; then
      echo "Force‑off $ACTIVEVM"
      virsh destroy "$ACTIVEVM"
    fi

    for SRC in "${DISK_PATH[@]}"; do
      FILENAME=$(basename "$SRC")
      [[ "$SRC" == "-" || "$SRC" == *.iso ]] && { echo "Skip removable/media: $SRC" && continue; }
      cp --reflink=auto --sparse=always "$SRC" "$BACKUP_DIR/$ACTIVEVM/$FILENAME"
    done

    echo "Starting $ACTIVEVM"
    virsh start "$ACTIVEVM"

  else # --clean
    echo "Cleaning backups of $ACTIVEVM"
    safe_rm "$BACKUP_DIR/$ACTIVEVM" || true
  fi

  echo "Completed $ACTIVEVM"
done
