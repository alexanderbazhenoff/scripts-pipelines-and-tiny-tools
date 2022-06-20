#!/usr/bin/env bash


# BACKUP SCRIPT FOR KVM VIRTUAL MACHINES
# Written by Alexander Bazhenov
#
# This Source Code Form is subject to the terms of the MIT
# License. If a copy of the MPL was not distributed with
# this file, You can obtain one at https://github.com/aws/mit-0
#
# WARNING! Running this script may cause potential data loss. Do on your own
# risk, otherwise you know what you're doing and accepted the license.

#        Usage:
#        kvm-backup.sh [command] <vmname1 vmname2 vmname3 ... vmnameN>
#
#        Commands:
#         --active           Create backup of running VM(s). Requierd
#                            qemu-guest-agent installed on virtual machine
#                            and qemu-channel device created
#         --stopped          Stop, create backup and run virtual machine
#         --clean            Clean previous packups from backup folder
#
#        Examples:
#         # kvm-backup.sh --active vmname1 vmname2
#        or
#         # kvm-backup.sh --clean vmname1 vmname2


# specify backup folder here:
BACKUP_DIR="/var/lib/libvirt/images/backup"

# specify log file path here:
LOGFILE="/var/log/kvmbackup.log"


# start new log
starting_logfile() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') Starting backup of $ACTIVEVM" | tee $LOGFILE
  mkdir -p "$BACKUP_DIR/$ACTIVEVM"
}

# backup config of VM
backup_vm_config() {
  RESULT_CMD=$(virsh dumpxml "$ACTIVEVM" > "$BACKUP_DIR/$ACTIVEVM/$ACTIVEVM.xml")
  echo "$(date +'%Y-%m-%d %H:%M:%S') Dumping xml... ${RESULT_CMD//\\n/ }" | tee -a $LOGFILE
}

# Getting a list and a path of disk images
vmdisks_get() {
  DISK_LIST=$(virsh domblklist $ACTIVEVM | awk '{if(NR>2)print}' | awk '{print $1}')
  DISK_PATH=$(virsh domblklist $ACTIVEVM | awk '{if(NR>2)print}' | awk '{print $2}')
  echo "$(date +'%Y-%m-%d %H:%M:%S') VM disk(s) / path of disk(s): ${DISK_LIST//$'\n'/, } -> ${DISK_PATH//$'\n'/, }" | \
    tee -a $LOGFILE
}


# entry
COMMAND_USE=$1; shift

if [[ $COMMAND_USE == "--active" ]] || [[ $COMMAND_USE == "--stopped" ]] || [[ $COMMAND_USE == "--clean" ]]; then

  #
  # making backup of running VMs on (active)
  #
  if [[ $COMMAND_USE == "--active" ]]; then
    for ACTIVEVM in "${@}"
    do
      starting_logfile
      backup_vm_config
      vmdisks_get

      # making a snapshot
      echo "$(date +'%Y-%m-%d %H:%M:%S') Creating snapshot of $ACTIVEVM" | tee -a $LOGFILE
      echo "$(date +'%Y-%m-%d %H:%M:%S') $(virsh snapshot-create-as --domain "$ACTIVEVM" snapshot --disk-only \
        --atomic --quiesce --no-metadata 2>&1)" 2>&1 | tee -a $LOGFILE
      if [[ ! -f "$ACTIVEVM".snapshot ]]; then
        echo "$(date +'%Y-%m-%d %H:%M:%S') WARNING! Snapshot wasn't created." | tee -a $LOGFILE
        echo "$(date +'%Y-%m-%d %H:%M:%S') There's no guaranty that resulting copy of VM may have consistent data." | \
          tee -a $LOGFILE
      fi

      for PATH_ITEM in $DISK_PATH
      do
        # getting filename from the path
        FILENAME=$(basename "$PATH_ITEM")
        echo "$(date +'%Y-%m-%d %H:%M:%S') Device image name is: $FILENAME" | tee -a $LOGFILE

        if [[ $PATH_ITEM == "-" ]] || [[ $PATH_ITEM =~ \.iso$ ]] || [[ $PATH_ITEM == \.ISO$ ]]; then
          echo "$(date +'%Y-%m-%d %H:%M:%S') Looks like removable media device slot, skipping" | tee -a $LOGFILE
        else
          # backup disk
          echo "$(date +'%Y-%m-%d %H:%M:%S') Creating backup of $ACTIVEVM $PATH_ITEM \
            $(cp "$PATH_ITEM" "$BACKUP_DIR/$ACTIVEVM/$FILENAME" 2>&1)" 2>&1 | tee -a $LOGFILE
        fi
      done
      for DISK_ITEM in $DISK_LIST
      do
        # getting a path to a snapshot
        SNAPSHOT_PATH=$(virsh domblklist "$ACTIVEVM" | grep "$DISK_ITEM" | awk '{print $2}')
        if [[ $SNAPSHOT_PATH == "-" ]] || [[ $SNAPSHOT_PATH =~ \.iso$ ]] || [[ $SNAPSHOT_PATH == \.ISO$ ]]; then
          echo "$(date +'%Y-%m-%d %H:%M:%S') Device path is $SNAPSHOT_PATH." | tee -a $LOGFILE
          echo "$(date +'%Y-%m-%d %H:%M:%S') Looks like removable media device, skipping" | tee -a $LOGFILE
        else
          echo "$(date +'%Y-%m-%d %H:%M:%S') Commit $SNAPSHOT_PATH of $ACTIVEVM to $DISK_ITEM image" | tee -a $LOGFILE

          # block-commit snapshot to disk image
          RESULT_CMD=$(virsh blockcommit "$ACTIVEVM" "$DISK_ITEM" --active --verbose --pivot 2> /dev/null || \
            echo "Nothing to commit with $DISK_ITEM or just failed.")
          echo "$(date +'%Y-%m-%d %H:%M:%S')${RESULT_CMD//$'\n'/ }" | tee -a $LOGFILE
          if [[ $SNAPSHOT_PATH =~ \.snapshot$ ]]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') Removing snapshot $SNAPSHOT_PATH. $(rm -f "$SNAPSHOT_PATH")" \
              2>&1 | tee -a $LOGFILE

          else
            echo "$(date +'%Y-%m-%d %H:%M:%S') $SNAPSHOT_PATH is not snapshot, skipping." | tee -a $LOGFILE
            echo "$(date +'%Y-%m-%d %H:%M:%S') Looks like you have copied images from running machine or no snapshot" \
              "created" | tee -a $LOGFILE
          fi
        fi
      done

      echo "$(date +'%Y-%m-%d %H:%M:%S') Backup of $ACTIVEVM finished" | tee -a $LOGFILE
    done
  exit 0
  fi

  #
  # making backup of stopped VMs (stop, backup, run)
  #
  if [[ $COMMAND_USE = "--stopped" ]]; then
    for ACTIVEVM in "${@}"
    do
      starting_logfile
      backup_vm_config
      vmdisks_get

      # creating backup subdirectory
      echo "$(date +'%Y-%m-%d %H:%M:%S') Creating backup subdirectory $RESULT_CMD" | tee -a $LOGFILE
      {
        mkdir "$BACKUP_DIR/$ACTIVEVM"
      } &> /dev/null

      # shutdown VM
      echo "$(date +'%Y-%m-%d %H:%M:%S') Waiting $ACTIVEVM shutdown..." | tee -a $LOGFILE
      {
        virsh shutdown "$ACTIVEVM"
      } &> /dev/null

      # wait while VM is not running
      COUNTER=300
        while ( virsh list | grep "$ACTIVEVM " > /dev/null ) && [[ $COUNTER -gt 0 ]]
        do
          sleep 1
          (( COUNTER-- )) || true
          echo "$(date +'%Y-%m-%d %H:%M:%S') Waiting $ACTIVEVM becomes down." | tee -a $LOGFILE
        done

      # perform force power-off if VM is still running
      if (virsh list | grep "$ACTIVEVM " > /dev/null)
      then
        echo "$(date +'%Y-%m-%d %H:%M:%S') Unable to shutdown $ACTIVEVM. Performing force power-off." | tee -a $LOGFILE
        {
          virsh destroy "$ACTIVEVM"
        } &> /dev/null

        while ( virsh list | grep "$ACTIVEVM " > /dev/null ) && [ $COUNTER -gt 0 ]
        do
          sleep 1
          (( COUNTER++ )) || true
        done

      else
        echo "$(date +'%Y-%m-%d %H:%M:%S') $ACTIVEVM stopped." | tee -a $LOGFILE
      fi

      for PATH_ITEM in $DISK_PATH
      do
        # getting filename from the path
        FILENAME=$(basename "$PATH_ITEM")
        if [[ $PATH_ITEM == "-" ]] || [[ $PATH_ITEM =~ \.iso$ ]] || [[ $PATH_ITEM == \.ISO$ ]]; then
          # skip "-" (not mounted) and ".iso"/".ISO" (CD-ROM image)
          echo "$(date +'%Y-%m-%d %H:%M:%S') Device image name is: $FILENAME" | tee -a $LOGFILE
          echo "$(date +'%Y-%m-%d %H:%M:%S') Looks like removable media device, skipping" | tee -a $LOGFILE
        else
          # backup disk
          RESULT_CMD=$(cp -rf "$PATH_ITEM" "$BACKUP_DIR/$ACTIVEVM/$FILENAME" > /dev/null)
          echo "$(date +'%Y-%m-%d %H:%M:%S') Backup of $ACTIVEVM $PATH_ITEM created $RESULT_CMD" | tee -a $LOGFILE
        fi
      done

      # run VM
      echo "$(date +'%Y-%m-%d %H:%M:%S') Staring $ACTIVEVM" | tee -a $LOGFILE
      {
        virsh start "$ACTIVEVM"
      } &> /dev/null
    done
  exit 0
  fi

  #
  # clean previous backups
  #
  if [[ $COMMAND_USE = "--clean" ]]; then
    for ACTIVEVM in "${@}"
    do
      # clean content of the folder
      echo "$(date +'%Y-%m-%d %H:%M:%S') Performing clean-up of $ACTIVEVM in $BACKUP_DIR" | tee -a $LOGFILE

      {
        rm -rfv "${BACKUP_DIR:?}/$ACTIVEVM"
      } &> /dev/null

      echo "$(date +'%Y-%m-%d %H:%M:%S') Clean-up of $ACTIVEVM in $BACKUP_DIR - OK." | tee -a $LOGFILE
    done
  exit 0
  fi
else
  #
  # Output when error command set
  #
  echo "kvm-backup: invalid option '$COMMAND_USE'"
  echo ""
  echo "Usage:"
  echo " kvm-backup.sh [command] <vmname1 vmname2 vmname3 ... vmnameN>"
  echo ""
  echo "Commands:"
  echo " --active           Create backup of running VM(s). Requierd"
  echo "                    qemu-guest-agent installed on virtual machine"
  echo "                    and qemu-channel device created"
  echo " --stopped          Stop, create backup and run virtual machine"
  echo " --clean            Clean previous packups from backup folder"
  echo ""
  echo "Examples:"
  echo " # kvm-backup.sh --active vmname1 vmname2"
  echo "or"
  echo " # kvm-backup.sh --clean vmname1 vmname2"
  exit 1
fi

