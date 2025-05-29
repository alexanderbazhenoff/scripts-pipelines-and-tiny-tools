# GitLab Backup and Restore

Scripts to create and restore GitLab backups.

**WARNING:** Running these scripts may result in data loss. Use them only if you understand what you're doing.
All actions are at your own risk.

## Contents

- [**gitlab_dump.sh**](gitlab_dump.sh) – creates a GitLab backup in `/var/opt/gitlab/backups`.
- [**gitlab_restore.sh**](gitlab_restore.sh) – restores GitLab from a backup located in `/var/opt/gitlab/backups`.
