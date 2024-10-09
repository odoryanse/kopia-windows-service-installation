@echo off
setlocal enabledelayedexpansion

:: Check if running with admin rights
openfiles >nul 2>&1
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process cmd -ArgumentList '/c %~f0 %*' -Verb RunAs"
    exit /b
)

:: Running with administrative privileges

set "psScriptPath=%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%psScriptPath%scripts/Main-Script.ps1"

pause
endlocal
exit /b