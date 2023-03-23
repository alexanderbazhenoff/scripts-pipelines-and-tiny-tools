@echo Off


:: Clean-up logs and stats on IxNetwork server.
:: --------------------------------------------------------------------------------------------------------------------
:: This Source Code Form is subject to the terms of the MIT License. If a copy of the MPL was not distributed with this
:: file, You can obtain one at: https://github.com/alexanderbazhenoff/data-scripts/blob/master/LICENSE


rem. > del_files.log
echo Clean-up IxNetwork server logs and stats started at %DATE% %TIME%... >> del_files.log
echo. >> del_files.log

echo "------------------------------------------------" >> del_files.log
for /D %%i in (C:\Users\*.*) do (
  echo %%i
  echo %%i >> del_files.log
  forfiles /P %%i\AppData\Local\Ixia\IxNetwork\data\logs /S /M * /D -7 /c "cmd /c echo @PATH"
  forfiles /P %%i\AppData\Local\Ixia\IxNetwork\data\logs /S /M * /D -7 /c "cmd /c rmdir /S /Q @PATH"
  forfiles /P %%i\AppData\Local\Ixia\IxNetwork\data\logs /S /M *.* /D -7 /c "cmd /c if @isdir==FALSE del /F /s /Q @PATH"
) >> del_files.log

echo "------------------------------------------------" >> del_files.log
for /D %%i in (C:\Users\*.*) do (
  echo %%i
  echo %%i >> del_files.log
  forfiles /p %%i\AppData\Local\Ixia\IxNetwork\logs /s /m "*" /d -7 /c "cmd /c echo @PATH"
  forfiles /p %%i\AppData\Local\Ixia\IxNetwork\logs /s /m "*" /d -7 /c "cmd /c del /F /s /Q @PATH"
) >> del_files.log

echo "------------------------------------------------" >> del_files.log
for /D %%i in (C:\Users\*.*) do (
  echo %%i
  echo %%i >> del_files.log
  forfiles /p %%i\AppData\Local\Ixia\IxNetwork\ErrorDumps /s /m "*" /d -3 /c "cmd /c echo @PATH"
  forfiles /p %%i\AppData\Local\Ixia\IxNetwork\ErrorDumps /s /m "*" /d -3 /c "cmd /c del /F /s /Q @PATH"
) >> del_files.log

echo "------------------------------------------------" >> del_files.log
for /D %%i in (C:\Users\*.*) do (
  echo %%i
  echo %%i >> del_files.log
  forfiles /p %%i\AppData\Local\Temp /s /m "*" /d -1 /c "cmd /c echo @PATH"
  forfiles /p %%i\AppData\Local\Temp /s /m "*" /d -1 /c "cmd /c del /F /s /Q @PATH"
) >> del_files.log
