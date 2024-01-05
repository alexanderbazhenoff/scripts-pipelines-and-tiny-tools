#!/usr/bin/env bash


# Create GitLab dump data
# Copyright (c) December, 2018, Aleksandr Bazhenov

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


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
        sudo gitlab-rake gitlab:backup:create SKIP=artifacts 2>&1 | \
                tee -a /var/opt/gitlab/backups/gitlab-dump.log | \
                grep -v " ... $" || exit 1
else
        exit 1
fi

echo "Dumping GitLab completed."
exit 0
