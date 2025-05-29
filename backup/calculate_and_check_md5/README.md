# MD5 Checksum: Calculation and Verification

Scripts for calculating and verifying MD5 checksums in a specified directory.

**WARNING:** By running these scripts, you acknowledge that you understand what you're doing. All actions are performed
at your own risk.

## Usage

1. Copy the contents of this folder to `/opt/scripts` on the Linux system where you want to process MD5 checksums.
2. Set the `$SOURCE_PATH` variable in [**calculate_md5.sh**](calculate_md5.sh) and [**check_md5.sh**](check_md5.sh).
3. *(Optional)* Customize [**check_error_notifications.sh**](check_error_notifications.sh) to send error messages to
   your messaging system.
4. Run `calculate_md5.sh` to generate MD5 checksums for files in `$SOURCE_PATH`, then run `check_md5.sh` to verify them.
