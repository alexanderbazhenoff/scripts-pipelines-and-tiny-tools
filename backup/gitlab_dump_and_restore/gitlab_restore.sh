#!/usr/bin/env bash


### Restore GitLab dump data ###

# WARNING! Running this file may cause a potential data loss and assumes you accept
# that you know what you're doing. All actions with this script at your own risk.

# More info: https://docs.gitlab.com/ee/raketasks/backup_restore.html

# Written by Alexander Bazhenov. December, 2018.
# This Source Code Form is subject to the terms of the BSD 3-Clause License.
# You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


rm -fr /var/opt/gitlab/backups/*
sudo chown git /var/opt/gitlab/backups
sudo gitlab-rake gitlab:backup:restore "$(ls /var/opt/gitlab/backups)" force=yes
sudo gitlab-ctl restart
