#!/usr/bin/env bash


# BACKUP SCRIPT FOR KVM VIRTUAL MACHINES

# Copyright (c) July 2018, Aleksandr Bazhenov

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

#        Usage:
#        kvm_backup.sh [command] <vm_name1 vm_name2 vm_name3 ... vm_nameN>
#
#        Commands (or actions):
#         --active           Create backup of running VM(s). Required
#                            qemu-guest-agent installed on virtual machine
#                            and qemu-channel device created
#         --stopped          Stop, create backup and run virtual machine
#         --clean            Clean previous backups from backup folder
#
#        Examples:
#         # kvm_backup.sh --active vm_name1 vm_name2
#        or
#         # kvm_backup.sh --clean vm_name1 vm_name2


# specify backup folder here:
BACKUP_DIR="/var/lib/libvirt/images/backup"

# specify log file path here:
LOGFILE="/var/log/kvm_backup.log"


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
vm_disks_get() {
  DISK_LIST=$(virsh domblklist "$ACTIVEVM" | awk '{if(NR>2)print}' | awk '{print $1}')
  DISK_PATH=$(virsh domblklist "$ACTIVEVM" | awk '{if(NR>2)print}' | awk '{print $2}')
  echo "$(date +'%Y-%m-%d %H:%M:%S') VM disk(s) / path of disk(s): ${DISK_LIST//$'\n'/, } -> ${DISK_PATH//$'\n'/, }" | \
    tee -a $LOGFILE
}

# Getting a block device which is a snapshot
get_vm_shapshots() {
  virsh domblklist "$1" | grep '.snapshot' | awk '{print $2}'
}


# entry
COMMAND_USE=$1; shift

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit
fi

if [[ $COMMAND_USE == "--active" ]] || [[ $COMMAND_USE == "--stopped" ]] || [[ $COMMAND_USE == "--clean" ]]; then

  #
  # making backup of running VMs on (active)
  #
  if [[ $COMMAND_USE == "--active" ]]; then
    for ACTIVEVM in "${@}"
    do
      starting_logfile
      backup_vm_config
      vm_disks_get

      # making a snapshot
      (
        VM_SNAPSHOT_CHECK="$(get_vm_shapshots "$ACTIVEVM")"
        if [[ -z "$VM_SNAPSHOT_CHECK" ]]; then
          echo "$(date +'%Y-%m-%d %H:%M:%S') Creating snapshot of $ACTIVEVM"
          echo "$(date +'%Y-%m-%d %H:%M:%S') $(virsh snapshot-create-as --domain "$ACTIVEVM" snapshot --disk-only \
            --atomic --quiesce --no-metadata 2>&1)"
        else
          echo "$ACTIVEVM already contains a snapshot: $VM_SNAPSHOT_CHECK, skipping creation."
          echo "Perhaps a previous backup job was interrupted."
        fi
        if [[ ! -f "$(get_vm_shapshots "$ACTIVEVM" | sed 's|\(.*\)/.*|\1|')/$ACTIVEVM.snapshot" ]]; then
          echo "$(date +'%Y-%m-%d %H:%M:%S') WARNING! Snapshot wasn't created."
          echo "$(date +'%Y-%m-%d %H:%M:%S') There's no guaranty that resulting copy of VM may have consistent data."
        fi

        for PATH_ITEM in $DISK_PATH
        do
          # getting filename from the path
          FILENAME=$(basename "$PATH_ITEM")
          echo "$(date +'%Y-%m-%d %H:%M:%S') Device image name is: $FILENAME" | tee -a $LOGFILE
          if [[ $PATH_ITEM == "-" ]] || [[ $PATH_ITEM =~ \.iso$ ]] || [[ $PATH_ITEM == \.ISO$ ]]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') Looks like removable media device slot, skipping"
          else
            # backup disk
            echo "$(date +'%Y-%m-%d %H:%M:%S') Creating backup of $ACTIVEVM $PATH_ITEM \
              $(cp "$PATH_ITEM" "$BACKUP_DIR/$ACTIVEVM/$FILENAME" 2>&1)"
          fi
        done

        for DISK_ITEM in $DISK_LIST
        do
          # getting a path to a snapshot
          SNAPSHOT_PATH=$(virsh domblklist "$ACTIVEVM" | grep "$DISK_ITEM" | awk '{print $2}')
          if [[ $SNAPSHOT_PATH == "-" ]] || [[ $SNAPSHOT_PATH =~ \.iso$ ]] || [[ $SNAPSHOT_PATH == \.ISO$ ]]; then
            echo "$(date +'%Y-%m-%d %H:%M:%S') Device path is $SNAPSHOT_PATH."
            echo "$(date +'%Y-%m-%d %H:%M:%S') Looks like removable media device, skipping"
          else
            echo "$(date +'%Y-%m-%d %H:%M:%S') Commit $SNAPSHOT_PATH of $ACTIVEVM to $DISK_ITEM image"

            # block-commit snapshot to disk image
            RESULT_CMD=$(virsh blockcommit "$ACTIVEVM" "$DISK_ITEM" --active --verbose --pivot 2> /dev/null || \
              echo "Nothing to commit with $DISK_ITEM or just failed.")
            echo "$(date +'%Y-%m-%d %H:%M:%S')${RESULT_CMD//$'\n'/ }"
            if [[ $SNAPSHOT_PATH =~ \.snapshot$ ]]; then
              echo "$(date +'%Y-%m-%d %H:%M:%S') Removing snapshot $SNAPSHOT_PATH. $(rm -f "$SNAPSHOT_PATH")" 2>&1
            else
              echo "$(date +'%Y-%m-%d %H:%M:%S') $SNAPSHOT_PATH is not snapshot, skipping."
              echo "$(date +'%Y-%m-%d %H:%M:%S') Looks like you have copied images from running machine or no" \
                "snapshot created"
            fi
          fi
        done
        echo "$(date +'%Y-%m-%d %H:%M:%S') Backup of $ACTIVEVM finished" | tee -a $LOGFILE
      ) 2>&1 | tee -a $LOGFILE
    done
  fi

  #
  # making backup of stopped VMs (stop, backup, run)
  #
  if [[ $COMMAND_USE = "--stopped" ]]; then
    for ACTIVEVM in "${@}"
    do
      starting_logfile
      backup_vm_config
      vm_disks_get

      COUNTER=100
      (
        # creating backup subdirectory
        echo "$(date +'%Y-%m-%d %H:%M:%S') Creating backup subdirectory... $(mkdir "$BACKUP_DIR/$ACTIVEVM" 2>&1 && \
          echo "OK.")"
        # shutdown VM
        echo "$(date +'%Y-%m-%d %H:%M:%S') Shutting down $ACTIVEVM... $(virsh shutdown "$ACTIVEVM" 2>&1 | \
          sed -z "s/\n//g")"
        # wait while VM is not running
        while (virsh list | grep "$ACTIVEVM " > /dev/null) && [[ $COUNTER -gt 0 ]]
        do
          sleep 3
          (( COUNTER-- )) || true
          echo "$(date +'%Y-%m-%d %H:%M:%S') Waiting $ACTIVEVM becomes down."
        done

        # perform force power-off if VM is still running
        if (virsh list | grep "$ACTIVEVM " > /dev/null); then
          echo "$(date +'%Y-%m-%d %H:%M:%S') Unable to shutdown $ACTIVEVM. Performing force power-off... $(virsh \
            destroy "$ACTIVEVM" 2>&1 | sed -z "s/\n//g")" 2>&1

          while (virsh list | grep "$ACTIVEVM " > /dev/null) && [[ $COUNTER -gt 0 ]]
          do
            sleep 1
            (( COUNTER++ )) || true
          done

        else
          echo "$(date +'%Y-%m-%d %H:%M:%S') $ACTIVEVM stopped."
        fi

        for PATH_ITEM in $DISK_PATH
        do
          # getting filename from the path
          FILENAME=$(basename "$PATH_ITEM")
          if [[ $PATH_ITEM == "-" ]] || [[ $PATH_ITEM =~ \.iso$ ]] || [[ $PATH_ITEM == \.ISO$ ]]; then
            # skip "-" (not mounted) and ".iso"/".ISO" (CD-ROM image)
            echo "$(date +'%Y-%m-%d %H:%M:%S') Device image name is: $FILENAME"
            echo "$(date +'%Y-%m-%d %H:%M:%S') Looks like removable media device, skipping"
          else
            # backup disk
            echo "$(date +'%Y-%m-%d %H:%M:%S') Copying $ACTIVEVM $PATH_ITEM image... $(cp -rf "$PATH_ITEM" \
              "$BACKUP_DIR/$ACTIVEVM/$FILENAME" 2>&1)"
          fi
        done

        # run VM
        echo "$(date +'%Y-%m-%d %H:%M:%S') Starting $ACTIVEVM $(virsh start "$ACTIVEVM" 2>&1 | sed -z "s/\n//g")"
      ) 2>&1 | tee -a $LOGFILE
    done
  fi

  #
  # clean previous backups
  #
  if [[ $COMMAND_USE = "--clean" ]]; then
    for ACTIVEVM in "${@}"
    do
      # clean content of the folder
      echo "$(date +'%Y-%m-%d %H:%M:%S') Performing clean-up of $ACTIVEVM in $BACKUP_DIR... $(rm \
        -rfv "${BACKUP_DIR:?}/$ACTIVEVM" 2>&1 && echo "OK")" 2>&1 | tee -a $LOGFILE
    done
  fi
else
  #
  # Output on invalid option
  #
  echo "Error! invalid option '$COMMAND_USE'"
  echo ""
  echo "Usage:"
  echo " kvm_backup.sh [command] <vm_name1 vm_name2 vm_name3 ... vm_nameN>"
  echo ""
  echo "Commands:"
  echo " --active           Create backup of running VM(s). Required"
  echo "                    qemu-guest-agent installed on virtual machine"
  echo "                    and qemu-channel device created"
  echo " --stopped          Stop, create backup and run virtual machine"
  echo " --clean            Clean previous backups from backup folder"
  echo ""
  echo "Examples:"
  echo " # kvm_backup.sh --active vm_name1 vm_name2"
  echo "or"
  echo " # kvm_backup.sh --clean vm_name1 vm_name2"
  exit 1
fi