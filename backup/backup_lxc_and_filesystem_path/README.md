# Backup LXC containers and filesystem paths

These scripts back up filesystem paths while preserving UID/GID, using `tar` and `gpg`. Entire containers can also be
saved and uploaded.

**WARNING! By running this script, you acknowledge that you know what you're doing. Use at your own risk.**

## Usage

1. Upload this folder content to your Linux system, e.g., inside of `/opt/scripts` folder.
2. (Optional) Set up your [rclone](https://rclone.org/drive/) to mount destination drive, e.g. Google Drive, Dropbox,
   Amazon Drive, Amazon S3 Compliant Storage Providers (including AWS, Alibaba, Ceph, Digital Ocean, Dreamhost, IBM COS,
   Minio, SeaweedFS, and Tencent COS), Google Cloud Storage, Hadoop distributed file system, Mail.Ru Cloud, Mega,
   Microsoft Azure Blob Storage, Microsoft OneDrive, OpenStack Swift, QingCloud Object Storage, Yandex Disk, Uptobox, 
   Zoho or another connection method(s) such as FTP, SSH, SFTP, or HTTP. Alternatively, mount your backup path manually,
   e.g. `/mnt/backup`.
3. Fill `empty_password.txt` with your GPG password if you want to encrypt the files, or leave it empty to skip
   encryption.
4. Edit the `lxc_exclude` file to specify paths to exclude.
5. (Optional) Put your error notification commands to `error_notification.sh` if you would like to receive error
   messages.
6. Edit your `backup_container.sh` with appropriate params of rclone mount (optional) and `backup_path_tar_gpg.sh` with
   appropriate backup and path params.
7. Run:

```bash
sudo /./opt/scripts/backup_conatainer.sh -b -p /opt/scripts/empty_password.txt
```

with predefined destination path, or:

```bash
sudo /./opt/scripts/backup_conatainer.sh --destination /mnt/backup --password-file /opt/scripts/empty_password.txt \
  --backup --debug
```

Restore files:

```bash
sudo /./opt/scripts/backup_conatainer.sh --source /mnt/backup --password-file /opt/scripts/empty_password.txt --restore
```

## Usage examples

Mount your remote drive to `/mnt/backup`, e.g. rclone pre-configured Google Drive mount. Add to `backup_container.sh`
the code below before backup block:

```bash
rm -rf /mnt/backup/*
sync; echo 3 > /proc/sys/vm/drop_caches; sync
rclone mount googledrive:vps0 /mnt/backup --drive-use-trash=false --daemon --allow-non-empty; sleep 5
```

Optionally remove old backups, e.g., older than 60 days:

```bash
cd "$BACKUP_DESTINATION" && find . -mtime +60 -exec rm -rf {} \;
```

Encrypted and tar.gz packed backup of LXC-container called **container_name** placed in default path should look like:

```bash
# call_function "/backup/path" "$BACKUP_DESTINATION" "$ACTION" (both variables are from backup_container.sh run args)
# (archive name) (password stored in a file) (encrypt=true) (compress=true) (clean destination=false) (exclude list)
# then run task_error to pass error code and path

process_path "/var/lib/lxc/container_name" "$BACKUP_DESTINATION" "$ACTION" \
"bareos_lxc_$(date +%y%m%d).tar.gz" "$(cat empty_password)" true true false "/opt/scripts/lxc_exclude"
task_error $? '/var/lib/lxc/container_name'

# You don’t need to clean up the destination path because the archive name includes the year, month, and day.
# Otherwise set them to true.

# You can also disable compression and keep encryption enabled. This will produce an encrypted .gpg file with a .enc
# extension.
```

At the end of the script unmount backup path:

```bash
sync; echo 3 > /proc/sys/vm/drop_caches; sync
sleep 60
fusermount -uz /mnt/backup
```

## Advanced usage

You can use `backup_path_tar_gpg.sh` directly to back up specific paths. Run `./backup_path_tar_gpg.sh --help` for usage
details.

## License

[BSD 3-Clause License](../../LICENSE)
