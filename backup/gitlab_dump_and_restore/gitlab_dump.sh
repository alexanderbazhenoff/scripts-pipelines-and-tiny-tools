#!/usr/bin/env bash

# Create GitLab dump data
# Copyright (c) December, 2018, Aleksandr Bazhenov

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.

# You can set you additional options like 'SKIP=artifacts' if built artifacts
# not required. More information:
# - https://docs.gitlab.com/ee/raketasks/backup_gitlab.html
# - https://docs.gitlab.com/ee/raketasks/backup_restore.html

set -x

if [[ -d /var/opt/gitlab/backups ]]; then
  sudo rm -rf /var/opt/gitlab/backups
fi

sudo mkdir /var/opt/gitlab/backups
sudo chown git /var/opt/gitlab/backups
if [[ -d /var/opt/gitlab/backups ]]; then
  sudo gitlab-rake gitlab:backup:create SKIP=artifacts 2>&1 |
    tee -a /var/opt/gitlab/backups/gitlab-dump.log |
    grep -v " ... $" || exit 1
else
  exit 1
fi

echo "Dumping GitLab completed."
exit 0
