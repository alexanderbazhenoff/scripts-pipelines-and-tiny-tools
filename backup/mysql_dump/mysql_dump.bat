title MySQL Dump batch file


:: Dump MySQL for Windows operation systems.
:: Written by Bazhenov Aleksandr. August, 2014.
:: -------------------------------------------------------------------------------------------------

:: This Source Code Form is subject to the terms of the BSD 3-Clause License. You can obtain one at:
:: https://github.com/alexanderbazhenoff/scripts-and-tools/blob/master/LICENSE


set CURRENT_TIME=%TIME:~0,2%
if "%CURRENT_TIME:~0,1%" == " " (set CURRENT_TIME=0%CURRENT_TIME:~1,1%)
set CURRENT_TIME=%CURRENT_TIME%_%TIME:~3,2%_%TIME:~6,2%
set TIME_FMT=%CURRENT_TIME%
set DATE_FMT=%DATE%


:: -------------------------------------------------------------------------------------------------
:: DB_PASS=database password
:: DB_NAME=database schema name
:: DB_HOST=host or ip
:: DB_LOGIN=database user login
:: BACKUP_PATH=path to backup
:: BACKUP_COPY_PATH=path to copy of backup (e.g. pre-mounted volume)
set DB_PASS=y0ur_p@ssw0rd
set DB_NAME=schema_name
set DB_HOST=localhost
set DB_PORT=3306
set DB_LOGIN=root
set BACKUP_PATH=D:\backup\db\
set BACKUP_COPY_PATH=Y:\backup\
:: -------------------------------------------------------------------------------------------------


(
    REM.
    echo MySQL Database Backup v0.1
    echo --------------------------
    echo.

    echo DB_HOST:DB_PORT @ USER = %DB_HOST%:%DB_PORT% @ %DB_LOGIN%
    echo Database tree name = %DB_NAME%
    echo Backup path = %BACKUP_PATH%
    echo NAS Backup path = %BACKUP_COPY_PATH%
    echo.
    echo %DATE% %TIME%: Backup Started

    set ERRORLEVEL=0
    MD %BACKUP_PATH%
    echo %DATE% %TIME%: Creating backup directory: %ERRORLEVEL% (0 if done)
    echo %DATE% %TIME%: Starting mysqldump
    echo.

    "C:\Program Files\MySQL\MySQL Server 5.6\bin\mysqldump.exe" -v --debug-info=TRUE --log-error=temp_log.txt ^
        --default-character-set=utf8 --host=%DB_HOST% --port=%DB_PORT% --user %DB_LOGIN% ^
        --password=%DB_PASS% %DB_NAME% > %BACKUP_PATH%mysql_backup__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.sql
    echo ------------------------------------------------------------------------------
    copy temp_log.txt %BACKUP_PATH%mysql_backup_log__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.txt

    echo %DATE% %TIME%: Creating 7zip archive
    7za.exe a -t7z %BACKUP_PATH%mysql_backup__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.7z ^
        %BACKUP_PATH%mysql_backup__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.sql
    echo ------------------------------------------------------------------------------
    7za.exe l %BACKUP_PATH%mysql_backup__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.7z
    echo ------------------------------------------------------------------------------
    7za.exe t %BACKUP_PATH%mysql_backup__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.7z *.*
    echo ------------------------------------------------------------------------------

    echo.
    del %BACKUP_PATH%mysql_backup__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.sql
    echo %DATE% %TIME% Deleting unarchived database file ERRORLEVEL is %ERRORLEVEL% (0 if done)

    echo %DATE% %TIME%: Making reserve copy...
    echo %DATE% %TIME%: Copying: %BACKUP_PATH%mysql_backup_log__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.txt
    echo TO: %BACKUP_COPY_PATH%backup_log.txt

    copy %BACKUP_PATH%mysql_backup_log__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.txt %BACKUP_COPY_PATH%backup_log.txt
    echo %DATE% %TIME%: Copying: %BACKUP_PATH%mysql_backup__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.7z
    echo TO: %BACKUP_COPY_PATH%mysql_backup.7z
    copy %BACKUP_PATH%mysql_backup__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.7z %BACKUP_COPY_PATH%mysql_backup.7z
    echo %DATE% %TIME%: Making reserve copy ERRORLEVEL is %ERRORLEVEL% (0 if done)
    echo.

    copy temp_log.txt %BACKUP_PATH%mysql_backup_log__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.txt
    copy temp_log.txt %BACKUP_COPY_PATH%backup_log.txt

    echo %DATE% %TIME%: Attempting to create log file: %ERRORLEVEL% (0 if done)
    set ERRORLEVEL=0

    echo ------------------------------------------------------------------------------
    echo.
    echo %DATE% %TIME%: Backup successfully DONE.
) >> temp_log.txt
copy temp_log.txt %BACKUP_PATH%mysql_backup_log__%DB_NAME%__%DATE_FMT%_%TIME_FMT%.txt
copy temp_log.txt %BACKUP_COPY_PATH%backup_log.txt
del temp_log.txt
