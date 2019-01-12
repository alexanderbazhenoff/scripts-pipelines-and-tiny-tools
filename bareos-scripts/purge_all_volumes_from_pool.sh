#!/bin/sh

# ---------------------------------------------------------------------------- #
#                Set all volumes in the pool to "purged" state                 #
# ---------------------------------------------------------------------------- #

# Set your pool name here 
poolname="Incremental"

volumes=`mysql -u root -B -e'select VolumeName from Media order by VolumeName;' bareos | \
    tail -n+2 | grep $poolname`
 
echo "This will purge all volumes in ${volumename}. Sleep 30 for sure."
sleep 30
 
for vol in `echo $volumes`
do
    echo "purge volume=${vol} yes" | bconsole
done
