@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install-all.ps1"
set "pack_exit=%ERRORLEVEL%"
echo.
if not "%pack_exit%"=="0" echo Installation reported an error. Read the message above.
pause
exit /b %pack_exit%
