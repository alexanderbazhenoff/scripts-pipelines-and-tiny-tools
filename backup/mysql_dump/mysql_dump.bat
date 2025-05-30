@echo off
:: MySQL Dump batch file.
:: Dumps a MySQL schema, compresses it with 7‑Zip and copies the archive to reserve storage.
:: Written by Bazhenov Aleksandr, August 2014.
:: BSD 3‑Clause License — see LICENSE in repository.

setlocal EnableExtensions EnableDelayedExpansion

:: Configuration.
set "DB_LOGIN=root"
set "DB_PASS=y0ur_p@ssw0rd"
set "DB_NAME=schema_name"
set "DB_HOST=localhost"
set "DB_PORT=3306"
set "BACKUP_PATH=D:\backup\db\"
set "COPY_PATH=Y:\backup\"
set "MYSQLDUMP=C:\Program Files\MySQL\MySQL Server 5.6\bin\mysqldump.exe"
set "SEVENZIP=7za.exe"

:: Generate timestamp in format YYYYMMDD_HHMMSS for filenames.
for /f "tokens=1-3 delims=:. " %%a in ("%TIME%") do (set hh=%%a & set mm=%%b & set ss=%%c)
if "%hh:~0,1%"==" " set hh=0%hh:~1,1%
for /f "tokens=2-4 delims=/.- " %%a in ("%DATE%") do set dt=%%a%%b%%c
set "ts=%dt%_%hh%%mm%%ss%"
set "fname=mysql_backup__%DB_NAME%__%ts%"

:: Simple sub‑routine that logs both to console and to a file in BACKUP_PATH.
:log
  echo [%DATE% %TIME%] %~1
  >>"%BACKUP_PATH%%fname%_log.txt" echo [%DATE% %TIME%] %~1
  goto :eof

:: Ensure backup and reserve directories exist.
if not exist "%BACKUP_PATH%" mkdir "%BACKUP_PATH%"
if not exist "%COPY_PATH%"   mkdir "%COPY_PATH%"

call :log "Backup started for %DB_NAME%."

:: Create schema dump.
"%MYSQLDUMP%" -u"%DB_LOGIN%" -p"%DB_PASS%" -h"%DB_HOST%" -P%DB_PORT% --default-character-set=utf8 "%DB_NAME%" ^
    >"%BACKUP_PATH%%fname%.sql"
if errorlevel 1 (call :log "ERROR: mysqldump failed." & exit /b 1)
call :log "Dump completed: %fname%.sql."

:: Compress dump to 7‑Zip archive.
call :log "Compressing dump."
"%SEVENZIP%" a -t7z "%BACKUP_PATH%%fname%.7z" "%BACKUP_PATH%%fname%.sql" >nul
if errorlevel 1 (call :log "ERROR: archive failed." & exit /b 1)
call :log "Archive created: %fname%.7z."

:: Remove raw SQL file to save space.
call :log "Deleting raw SQL file."
del "%BACKUP_PATH%%fname%.sql"

:: Copy archive and log to reserve storage.
for %%F in ("%fname%.7z" "%fname%_log.txt") do (
  call :log "Copying %%~F to reserve."
  copy /Y "%BACKUP_PATH%%%~F" "%COPY_PATH%" >nul
  if errorlevel 1 (
    call :log "WARNING: failed to copy %%~F."
  ) else (
    call :log "Copied %%~F to reserve."
  )
)

call :log "Backup completed successfully."
endlocal
