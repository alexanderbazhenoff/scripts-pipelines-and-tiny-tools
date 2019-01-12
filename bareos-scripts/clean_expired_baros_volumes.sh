#!/bin/bash

# ----------------------------------------------------------------------------------- #
#                Clean expired volumes from Bareos storage pool script                #
# ----------------------------------------------------------------------------------- #
# Requirments:
#    * permissions to run 'bconsole' command and acess $poolpath
#      (don't mind if you run this script from bareos Admin Job you're, otherwise -
#      edit /etc/sudoers or run from root)
#    * git pacakge (apt or yum install git)
#    * shflags library: https://code.google.com/archive/p/shflags/
#      or: git clone https://github.com/kward/shflags.git
#
# Usage:
#    # ./clean_expired_baros_volumes.sh --name Full- --action delete --expire 10 --filter Pruned
# or
#   # ./clean_expired_baros_volumes.sh --help
#
# Use "--test yes" key for testmode (only output, no actions).
# For more information about volume status read Bareos manual:
#   * http://doc.bareos.org/master/html/bareos-manual-main-reference.html


# Path of logs file
# Leave empty if you don't wish additional log file
logpath=""

# Path of the pool
poolpath="/mnt/nas"


# Process volume function. In test mode prints only command (use for debug).
function process_volume {
        echo "Processing: $filename | $filedate"
        if [ ! -z "$logpath" ]; then
                echo "Processing: $filename | $filedate"
        fi

        if [ $FLAGS_test = "no" ]; then
                echo "$FLAGS_action volume=${filename}${i} yes" | bconsole
                # Perform physical delete of file from $poolpath when "--action delete".
                # Doesn't matter if this volume is absent in bareos database, this will be removed.
                if [ $FLAGS_action = "delete" ]; then
                        echo "Perfomring physical delete of ${filename} from ${poolpath}..."
                        rm -f $poolpath/$filename && echo "Removed." || echo "${filename} not found." 
                fi
        else
                echo "(test mode): echo \"$FLAGS_action volume=${filename}${i} yes\" | bconsole"
        fi
}

# getting shflags to current directory if absent
if [ ! -d "shflags" ]; then
        git clone https://github.com/kward/shflags.git
        chmod +x shflags/shflags
        chmod +x shflags/shflags_test_helpers
fi

. ./shflags/shflags
DEFINE_string name 'Full-' "Pool name, e.g. \"Full-\"" n
DEFINE_string action 'delete' "Action after expiration days" a
DEFINE_string expire '31' "Filter by time expiration (days)" e
DEFINE_string filter 'none' "Filter by status of volume" f
DEFINE_string test 'no' "Switch to 'yes' for test mode (only output, no action)" t
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

echo "Performing ${FLAGS_action} \"${FLAGS_name}\" volumes after ${FLAGS_expire} days,"
echo "filtered by \"${FLAGS_filter}\" status... Test mode: ${FLAGS_test}"
if [ $FLAGS_action = "delete" ] || \
   [ $FLAGS_action = "prune" ] || \
   [ $FLAGS_action = "purge" ]; then
        cd $poolpath
        filelist=$(find . -mtime +$FLAGS_expire -print | grep $FLAGS_name | sed 's/[./]//g')
        echo "$fileset"
        for filename in $filelist
        do
                filedate=`ls -lh $filename | awk '{print $7" "$6" "$8}'`
                if [ $FLAGS_filter = "none" ]; then
                        echo "filter is none"
                        process_volume
                else
                        # filter by volume status if $FLAGS_filter is not 'none'
                        [[ ! -z $(echo "list volume" | bconsole | grep $FLAGS_filter | grep $filename | cut -d ' ' -f6) ]] && \
                        process_volume
                fi
        done
else
        echo "Error! Uknown action: $FLAGS_action"
        echo "Use \"prune\", \"purge\" or \"delete\"."
        exit 1
fi
