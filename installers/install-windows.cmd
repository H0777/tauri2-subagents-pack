@echo off
cd /d "%~dp0"
echo ===================================================
echo  Tauri 2 Subagents Pack - Windows Installer
echo ===================================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\scripts\install-all.ps1"
set "pack_exit=%ERRORLEVEL%"
echo.
if not "%pack_exit%"=="0" echo Installation reported an error. Read the message above.
pause
exit /b %pack_exit%
