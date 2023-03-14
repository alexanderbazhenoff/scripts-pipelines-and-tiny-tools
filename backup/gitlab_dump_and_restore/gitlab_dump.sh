#!/usr/bin/env bash


### Create GitLab dump data ###

# Written by Alexander Bazhenov December, 2018.
# This Source Code Form is subject to the terms of the MIT License. If a
# copy of the MPL was not distributed with this file, You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE

set -x

if ls /var/opt/gitlab/ | grep -q backups; then
        sudo rm -rf /var/opt/gitlab/backups
fi

sudo mkdir /var/opt/gitlab/backups
sudo chown git /var/opt/gitlab/backups
if ls /var/opt/gitlab/ | grep -q backups; then
        sudo gitlab-rake gitlab:backup:create SKIP=artifacts 2>&1 | \
                tee -a /var/opt/gitlab/backups/gitlab-dump.log | \
                grep -v " ... $" || exit 1
else
        exit 1
fi

echo "Dumping GitLab completed, exit 0"
exit 0
