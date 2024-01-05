#!/usr/bin/env bash


# Example how to perform MySQL DB dump.
# -------------------------------------------------------------------------------------------------
# This Source Code Form is subject to the terms of the BSD 3-Clause License. You can obtain one at:
# https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


DB_USER='root'
DB_PASSWORD='my_password'
DB_NAME='db_name'
DB_BACKUP_PATH='/opt/backup'
DB_BACKUP_FILENAME='db_name_dump.sql'
MYSQL_SOCKET_PATH='/var/lib/mysql/mysql.sock'


rm -rf "${DB_BACKUP_PATH:?}/"* || true
mysqldump -u"$DB_USER" -p"$DB_PASSWORD" --quick --max_allowed_packet=1024M --compress --skip-lock-tables \
  --verbose $DB_NAME --socket=$MYSQL_SOCKET_PATH --single-transaction > "$DB_BACKUP_PATH$DB_BACKUP_FILENAME"
