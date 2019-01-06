#!/bin/bash

###
############ BACKUP SCRIPT FOR KVM VIRTUAL MACHINES ##############
###

#        Usage:
#        kvm-backup.sh [command] <vmname1 vmname2 vmname3 ... vmnameN>
#
#        Commands:
#         --active           Create backup of running VM(s). Requierd
#                            qemu-guest-agent installed on virtual machine
#                            and qemu-channel device created
#         --stoped           Stop, create backup and run virtual machine
#         --clean            Clean previous packups from backup folder
#
#        Examples:
#         # kvm-backup.sh --active vmname1 vmname2
#        or
#         # kvm-backup.sh --clean vmname1 vmname2


#
# SETTINGS:
#

starting_logfile() {
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Starting backup of $activevm"
			mkdir -p $backup_dir/$activevm

			# starting log
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Starting backup of $activevm" >> $logfile
}

backup_vm_config() {
			# backup config of VM
			result_cmd=$(virsh dumpxml $activevm > $backup_dir/$activevm/$activevm.xml)
			result_cmd="${result_cmd//\\n/ }"
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Dumping xml... $result_cmd" >> $logfile
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Dumping xml... $result_cmd"
}

vmdisks_get() {
			# Getting a list and a path of disk images
			disk_list=`virsh domblklist $activevm | awk '{if(NR>2)print}' | awk '{print $1}'`
			disk_path=`virsh domblklist $activevm | awk '{if(NR>2)print}' | awk '{print $2}'`
			disk_list_hr=$(echo $disk_list | sed "s/ /, /g")
			disk_path_hr=$(echo $disk_path | sed "s/ /, /g")
                        echo "`date +"%Y-%m-%d_%H-%M-%S"` VM disk(s) / path of disk(s): $disk_list_hr -> $disk_path_hr"
}

# specify backup folder here:
backup_dir=/var/lib/libvirt/images/backup

# specify log file path here:
logfile="/var/log/kvmbackup.log"


# getting script action from run command
command_use=$1; shift
data=`date +%Y-%m-%d`
NL=$'\n'

if [ $command_use = "--active" ] || [ $command_use = "--stoped" ] || [ $command_use = "--clean" ]; then

	#
	# making backup of running VMs (without shutdown)
	#
	if [ $command_use = "--active" ]; then
		for activevm in "${@}"
		do
			starting_logfile
			backup_vm_config
			vmdisks_get

			# making a snapshot
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Creating snapshots of $activevm" >> $logfile
			result_cmd=$(virsh snapshot-create-as --domain $activevm snapshot --disk-only --atomic --quiesce --no-metadata)

			echo "`date +"%Y-%m-%d_%H-%M-%S"` $result_cmd" >> $logfile
			echo "`date +"%Y-%m-%d_%H-%M-%S"` $result_cmd"

			for path in $disk_path
				do
					# getting filename from the path
	                                filename=`basename $path`
	                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Device image name is: $filename" >> $logfile
	                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Device image name is: $filename"

					if [[ $path == "-" ]] || [[ $path =~ \.iso$ ]] || [[ $path == \.ISO$ ]]; then
                                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Looks like removable media device slot, skipping" >> $logfile
                                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Looks like removable media device slot, skipping"
					else
                                                # backup disk
                                                result_cmd=$(cp $path $backup_dir/$activevm/$filename)
                                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Creating backup of $activevm $path $result_cmd" >> $logfile
                                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Creating backup of $activevm $path $result_cmd"
					fi
				done
			for disk in $disk_list
				do
					# getting a path to a snapshot
                                        snap_path=`virsh domblklist $activevm | grep $disk | awk '{print $2}'`
					if [[ $snap_path == "-" ]] || [[ $snap_path =~ \.iso$ ]] || [[ $snap_path == \.ISO$ ]]; then
						echo "`date +"%Y-%m-%d_%H-%M-%S"` Device path is $snap_path. Looks like removable media device slot, skipping" >> $logfile
                                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Device path is $snap_path. Looks like removable media device slot, skipping"
					else
						echo "`date +"%Y-%m-%d_%H-%M-%S"` Commiting $snap_path of $activevm to $disk image" >> $logfile
                                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Commiting $snap_path of $activevm to $disk image"

						# blockcommitting snapshot with disk image
						{
							result_cmd=$(virsh blockcommit $activevm $disk --active --verbose --pivot)
						} &> /dev/null
							result_cmd="${result_cmd//$'\n'/ }"

						echo "`date +"%Y-%m-%d_%H-%M-%S"`$result_cmd" >> $logfile
						echo "`date +"%Y-%m-%d_%H-%M-%S"`$result_cmd"

		                                # remove snapshot
		                                echo "`date +"%Y-%m-%d_%H-%M-%S"` Removing $activevm snapshot: $snap_path" >> $logfile
                		                echo "`date +"%Y-%m-%d_%H-%M-%S"` Removing $activevm snapshot: $snap_path"
		                                rm $snap_path

					fi
				done

				echo "`date +"%Y-%m-%d_%H-%M-%S"` Backup of $activevm finished" >> $logfile
				echo "`date +"%Y-%m-%d_%H-%M-%S"` Backup of $activevm finished"

		done
	exit 0
	fi

	#
	# making backup of stoped VMs (stop, backup, run)
	#
	if [ $command_use = "--stoped" ]; then
		for activevm in "${@}"
		do
			starting_logfile
			backup_vm_config
			vmdisks_get

			# creating backup subdirectory
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Creating backup subdirectory $result_cmd" >> $logfile
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Creating backup subdirectory $result_cmd"
			{
				mkdir $backup_dir/$activevm
			} &> /dev/null

			# shutdown VM
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Waiting $activevm shutdown..." >> $logfile
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Waiting $activevm shutdown..."
			{
				virsh shutdown $activevm
			} &> /dev/null

			# wait a limited time for the VM to be not running
			count=300
    			while ( virsh list | grep "$activevm " > /dev/null ) && [ $count -gt 0 ]
				do
					sleep 1
					let count=count-1
					echo "`date +"%Y-%m-%d_%H-%M-%S"` Waiting $activevm becomes down."
				done

			# perform force power-off if VM is still running
			if (virsh list | grep "$activevm " > /dev/null)
			then
				echo "`date +"%Y-%m-%d_%H-%M-%S"` Unable to shutdown $activevm. Performing force power-off." >> $logfile
				echo "`date +"%Y-%m-%d_%H-%M-%S"` Unable to shutdown $activevm. Performing force power-off."
				{
					virsh destroy $activevm
				} &> /dev/null

				while ( virsh list | grep "$activevm " > /dev/null ) && [ $count -gt 0 ]
				do
					sleep 1
					let count=count-1
				done

			else
				echo "`date +"%Y-%m-%d_%H-%M-%S"` $activevm stoped." >> $logfile
				echo "`date +"%Y-%m-%d_%H-%M-%S"` $activevm stoped."
			fi

			for path in $disk_path
			do
				# getting filename from the path
				filename=`basename $path`
				if [[ $path == "-" ]] || [[ $path =~ \.iso$ ]] || [[ $path == \.ISO$ ]]; then
					# skip "-" (not mounted) and ".iso"/".ISO" (CD-ROM image)
                                	echo "`date +"%Y-%m-%d_%H-%M-%S"` Device image name is: $filename" >> $logfile
                                        echo "`date +"%Y-%m-%d_%H-%M-%S"` Device image name is: $filename"
					echo "`date +"%Y-%m-%d_%H-%M-%S"` Looks like removable media device slot, skipping" >> $logfile
                                        echo "`date +"%Y-%m-%d_%H-%M-%S"` Looks like removable media device slot, skipping"
				else
					# backup disk
					result_cmd=$(cp -rf $path $backup_dir/$activevm/$filename > /dev/null)
					echo "`date +"%Y-%m-%d_%H-%M-%S"` Backup of $activevm $path created $result_cmd" >> $logfile
					echo "`date +"%Y-%m-%d_%H-%M-%S"` Backup of $activevm $path created $result_cmd"
				fi
			done

			# run VM
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Staring $activevm" >> $logfile
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Starting $activevm"
			{
				virsh start $activevm
			} &> /dev/null
		done
	exit 0
	fi

	#
	# clean previous backups
	#
	if [ $command_use = "--clean" ]; then
		for activevm in "${@}"
		do
			# clean content of the folder
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Performing clean-up of $activevm in $backup_dir" >> $logfile
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Performing clean-up of $activevm in $backup_dir"

			{
				rm -rfv $backup_dir/$activevm
			} &> /dev/null

			echo "`date +"%Y-%m-%d_%H-%M-%S"` Clean-up of $avtivevem in $backup_dir - OK." >> $logfile
			echo "`date +"%Y-%m-%d_%H-%M-%S"` Clean-up of $avtivevem in $backup_dir - OK."
		done
	exit 0
	fi
else
	#
	# Output when error command set
	#
	echo "kvm-backup: invalid option '$command_use'"
	echo " "
	echo "Usage:"
	echo " kvm-backup.sh [command] <vmname1 vmname2 vmname3 ... vmnameN>"
	echo " "
	echo "Commands:"
	echo " --active           Create backup of running VM(s). Requierd"
	echo "                    qemu-guest-agent installed on virtual machine"
	echo "                    and qemu-channel device created"
	echo " --stoped           Stop, create backup and run virtual machine"
	echo " --clean            Clean previous packups from backup folder"
	echo " "
	echo "Examples:"
	echo " # kvm-backup.sh --active vmname1 vmname2"
	echo "or"
	echo " # kvm-backup.sh --clean vmname1 vmname2"
	exit 1
fi
