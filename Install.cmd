@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
title Tauri 2 Subagents Pack - Installer

echo ===================================================================
echo    Tauri 2 + Rust Subagents Pack (v2.0.0) - Installer
echo ===================================================================
echo.
echo   [1] Install for all detected AI coding tools (Recommended)
echo   [2] Scan and list detected AI coding tools
echo   [3] Exit
echo.
set /p choice="Select an option [1-3, Default=1]: "
if "%choice%"=="" set choice=1
if "%choice%"=="1" goto do_install
if "%choice%"=="2" goto do_list
if "%choice%"=="3" goto do_exit
goto do_install

:do_install
echo.
echo ===================================================================
echo  Starting installation...
echo ===================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-all.ps1"
goto finish

:do_list
echo.
echo ===================================================================
echo  Scanning detected AI tools and environments...
echo ===================================================================
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\install-all.ps1" -List
goto finish

:finish
set "pack_exit=%ERRORLEVEL%"
echo.
if not "%pack_exit%"=="0" (
    echo [X] Installation reported an issue. Please review the details above.
) else (
    echo [OK] Done.
)
echo.
pause
exit /b %pack_exit%

:do_exit
exit /b 0
