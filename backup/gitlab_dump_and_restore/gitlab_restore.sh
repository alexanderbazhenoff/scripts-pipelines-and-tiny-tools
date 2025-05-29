#!/usr/bin/env bash

# Restore GitLab dump data
# Copyright (c) December, 2018. Aleksandr Bazhenov

# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# If a copy of the source distributed without this file, you can obtain one at:
# https://github.com/alexanderbazhenoff/scripts-pipelines-and-tiny-tools/blob/master/LICENSE

# WARNING! This script may cause irreversible data loss. Use at your own risk.
# More info: https://docs.gitlab.com/ee/raketasks/backup_restore.html

sudo find /var/opt/gitlab/backups -mindepth 1 -exec rm -rf {} +
sudo chown git /var/opt/gitlab/backups
sudo gitlab-rake gitlab:backup:restore "$(ls -1 "$BACKUP_DIR"/*.tar 2>/dev/null | sort | tail -n 1)" force=yes
sudo gitlab-ctl restart
