#!/usr/bin/env bash

# Create GitLab backup dump.
# Copyright (c) December, 2018, Aleksandr Bazhenov

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

# WARNING! Running this script may result in potential data loss.
# Proceed only if you understand what you're doing. Use at your own risk.

# You can set additional options like 'SKIP=artifacts' if build artifacts
# are not required. More information:
# - https://docs.gitlab.com/ee/raketasks/backup_gitlab.html
# - https://docs.gitlab.com/ee/raketasks/backup_restore.html

set -ex

sudo mkdir -p /var/opt/gitlab/backups
sudo find /var/opt/gitlab/backups -mindepth 1 -exec rm -rf {} +

sudo chown git /var/opt/gitlab/backups
if ! sudo gitlab-rake gitlab:backup:create SKIP=artifacts 2>&1 | tee -a /var/opt/gitlab/backups/gitlab-dump.log; then
  echo "Backup failed."
  exit 1
fi
echo "Dumping GitLab completed."
