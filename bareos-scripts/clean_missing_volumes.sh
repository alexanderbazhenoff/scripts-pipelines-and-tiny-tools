
#!/bin/bash

# ---------------------------------------------------------------------------- #
#     Physically delete non-existent volumes from Pool in the bareos database. #
# ---------------------------------------------------------------------------- #

# Set Pool path
poolpath=/mnt/nas

cd $poolpath
for i in `find . -maxdepth 1 -type f -printf "%f\n"`; do
        echo "list volume=$i" | bconsole | if grep --quiet "No results to list"; then
                echo "$i is ready to be deleted"
                rm -f $poolpath/$i
        fi
done

exit 0
