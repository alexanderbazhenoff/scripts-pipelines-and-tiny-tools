#!/bin/bash


# ----------------------------------------------------------------------------------- #
#                Clean expired volumes from Bareos storage pool script                #
# ----------------------------------------------------------------------------------- #
# Requirments:
#    * git pacakge (apt or yum install git)
#    * shflags library: https://code.google.com/archive/p/shflags/
#      or: git clone https://github.com/kward/shflags.git


# Path of logs file
# Leave empty if you don't wish additional log file
logpath=""

# Path of the pool
poolpath="/mnt/nas"

# getting shflags to current directory if absent
if [ ! -d "shflags" ]; then
	git clone https://github.com/kward/shflags.git
	chmod +x shflags/shflags
	chmod +x shflags/shflags_test_helpers
fi

. ./shflags/shflags
DEFINE_string name 'Full-' "Pool name, e.g. \"Full-\"" n
DEFINE_string action 'delete' "Action after expiration days" a
DEFINE_string expire '31' "Expire after (days)" e
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"
echo "Performing ${FLAGS_action} \"${FLAGS_name}\" volumes after ${FLAGS_expire} days..."

if [ $FLAGS_action = "delete" ] || \
   [ $FLAGS_action = "prune" ] || \
   [ $FLAGS_action = "purge" ]; then
	cd $poolpath
	filelist=$(find . -mtime +$FLAGS_expire -print | grep $FLAGS_name | sed 's/[./]//g')
	for filename in $filelist
	do
		filedate=`ls -lh $filename | awk '{print $7" "$6" "$8}'`
		echo "Processing: $filename | $filedate"
		if [ ! -z "$logpath" ]; then
		        echo "Processing: $filename | $filedate"
		fi
		echo "$FLAGS_action volume=${filename}${i} yes" | bconsole
	done
else
	echo "Error! Uknown action: $FLAGS_action"
	echo "Use \"prune\", \"purge\" or \"delete\"."
	exit 1
fi
