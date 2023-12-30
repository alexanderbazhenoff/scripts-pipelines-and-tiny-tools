#!/usr/bin/env bash

BACKUP_MODE=$1
VM_NAME=$2

./kvm_backup.sh --"$BACKUP_MODE" "$VM_NAME"