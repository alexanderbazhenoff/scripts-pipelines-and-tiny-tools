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

# Specify backup folder here:
BACKUP_DIR="/var/lib/libvirt/images/backup"
# Specify log file path here:
LOGFILE="/var/log/kvm_backup.log"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') [$ACTIVE_VM] $1"
  if [[ ${2:-} == true ]]; then
    exit 1
  fi
}

usage() {
  cat <<EOF
Usage: $0 [--active|--stopped|--clean] <vm1 vm2 ...>

  --active      Create backup of running VM(s). Required
                qemu-guest-agent installed on virtual machine
                and qemu-channel device created.
  --stopped     Stop, create backup and run virtual machine.
  --clean       Clean previous backups from backup folder.

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
  log "Starting backup"
  mkdir -p "$BACKUP_DIR/$ACTIVE_VM"
}

backup_vm_config() {
  virsh dumpxml "$ACTIVE_VM" >"$BACKUP_DIR/$ACTIVE_VM/$ACTIVE_VM".xml
  log "Saved domain XML"
}

copy_base_images() {
  log "Copying base images"
  for SRC in "${BASE_PATH[@]}"; do
    [[ "$SRC" == "-" || "$SRC" == *.iso ]] && {
      log "Skip media: $SRC"
      continue
    }
    log "Copying base image $SRC to backup"
    cp --reflink=auto --sparse=always "$SRC" "$BACKUP_DIR/$ACTIVE_VM/"
  done
}

# Double‑checks the path we are about to delete.
safe_rm() {
  local target="$1"
  [[ -z "$target" || "$target" == "/" ]] && log "Refusing to remove empty or root path" true
  [[ ! -e "$target" ]] && log "safe_rm: '$target' does not exist" true
  rm -rf --one-file-system -- "$target"
}

# Getting a list and a path of disk images.
vm_disks_get() {
  DISK_LIST=()
  DISK_PATH=()
  while IFS=' ' read -r tgt src _; do
    [[ -z $src || $src == "-" ]] && continue
    DISK_LIST+=("$tgt")
    DISK_PATH+=("$src")
  done < <(virsh domblklist "$ACTIVE_VM" | awk 'NR>2')
  log "Disk targets: ${DISK_LIST[*]}"
  log "Disk paths: ${DISK_PATH[*]}"
}

# Getting a block device which is a snapshot.
get_snapshots() {
  virsh snapshot-list --domain "$ACTIVE_VM" --no-metadata --name 2>/dev/null || true
}

# Entry point.
set -euo pipefail
shopt -s nocasematch

[[ $# -lt 2 ]] && usage
COMMAND_USE="$1"
shift
[[ $EUID -ne 0 ]] && log "Please run as root (e.g. sudo $0 ...)" true

case "$COMMAND_USE" in
--active | --stopped | --clean) ;;
*) usage ;;
esac

LOG_INITIALIZED=0
init_log

for ACTIVE_VM in "$@"; do
  SNAPSHOT_NAME="snapshot-${ACTIVE_VM}-$(date +%s%N)"
  start_log
  backup_vm_config
  vm_disks_get
  BASE_LIST=("${DISK_LIST[@]}")
  BASE_PATH=("${DISK_PATH[@]}")

  if [[ $COMMAND_USE == "--active" ]]; then
    log "Creating live snapshot $SNAPSHOT_NAME"
    if ! get_snapshots | grep -Fxq "$SNAPSHOT_NAME"; then
      virsh snapshot-create-as --domain "$ACTIVE_VM" "$SNAPSHOT_NAME" --disk-only --atomic --quiesce --no-metadata
    else
      log "Snapshot $SNAPSHOT_NAME already exists – skipping"
    fi

    vm_disks_get
    SNAP_PATH=("${DISK_PATH[@]}")
    copy_base_images

    log "Committing and removing snapshot layers"
    for disk in "${BASE_LIST[@]}"; do
      log "Blockcommit disk $disk"
      virsh blockcommit "$ACTIVE_VM" "$disk" --active --verbose --pivot || echo "Nothing to commit for $disk"
    done
    vm_disks_get
    log "Removing snapshot files"
    for p in "${SNAP_PATH[@]}"; do
      [[ $p == *.snapshot ]] || continue
      log "Removing leftover snapshot layer $p"
      rm -f -- "$p"
    done
    log "Active backup completed"

  elif [[ $COMMAND_USE == "--stopped" ]]; then
    log "Shutting down VM"
    if ! virsh shutdown "$ACTIVE_VM"; then
      log "Shutdown failed, waiting anyway..."
    fi

    COUNTER=40
    while virsh list --name | grep -Fxq "$ACTIVE_VM" && ((COUNTER-- > 0)); do
      sleep 3
    done
    if virsh list --name | grep -Fxq "$ACTIVE_VM"; then
      log "Force‑off"
      virsh destroy "$ACTIVE_VM"
    fi

    log "Copying stopped VM disks"
    copy_base_images
    log "Starting VM"
    virsh start "$ACTIVE_VM"
  else
    log "Cleaning old backups"
    safe_rm "$BACKUP_DIR/$ACTIVE_VM" || true
  fi

  log "All operations finished"
done
