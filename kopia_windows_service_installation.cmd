@echo off
setlocal enabledelayedexpansion
:: BatchGotAdmin
::-------------------------------------
REM  --> Check for permissions
    IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %USERNAME%
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
:--------------------------------------   
if "%~1"=="" (
  set logged_user=%USERNAME%
) else (
  set logged_user=%1
)

for /f %%A in ('"prompt $H &echo on &for %%B in (1) do rem"') do set BS=%%A
set nl=^


REM Multiple Lines
set bar=========================================================================
set title=Kopia Windows Service Installation v0.9.0 - Odoryanse - VOZ Forum F13!nl!!nl!
set print=!title!
set script_error=0

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set print=!print!!Bar!!nl!Installing Kopia Windows Service!!nl!
call :PRINTSCREEN
call :SAVESCREEN
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:GRANTSERVICELOGONRIGHT
%~dp0tools\PrivMan.exe -a %logged_user% -g SeServiceLogonRight -c %COMPUTERNAME% >nul

:TESTSERVICELOGONRIGHT
%~dp0tools\PrivMan.exe -a %logged_user% -t SeServiceLogonRight -c %COMPUTERNAME% >nul
if %ERRORLEVEL% NEQ 1 (
  set print=- [ERROR] Unable to grant Service Login Permission
  set script_error=1
  goto :FINISH
)
if %ERRORLEVEL% EQU 1 (
  set print=- Account "%logged_user%" has been granted Service Login Permission.
  call :PRINTSCREEN
)

:INSTALLKOPIASERVICE
%~dp0tools\shawl.exe add ^
  --name Kopia ^
  --log-dir %~dp0logs ^
  -- %~dp0kopia-service.cmd >nul

:TESTINSTALLKOPIASERVICE
if %ERRORLEVEL% NEQ 0 (
  set print=- [ERROR] Failed to create the Kopia service
  set script_error=1
  goto :FINISH
)
if %ERRORLEVEL% EQU 0 (
  set print=- Kopia service has been created.
  call :PRINTSCREEN
)

:CONFIGKOPIASERVICELOGON
set print=
call :PRINTSCREEN
set /p win_pass=.%BS%  ^> Enter the password for the Windows account "%logged_user%"(enter if blank): 
echo.  ^> Windows account: %logged_user%
echo.  ^> Windows password: !win_pass!

choice /C YN /N /M "!nl!.%BS%  Are you sure? Press Y for Yes, N for No: "
if %ERRORLEVEL% NEQ 1 (
  goto :CONFIGKOPIASERVICELOGON
)

sc config Kopia  obj= ".\%logged_user%" password= "%win_pass%" >nul
set win_pass=

:TESTCONFIGKOPIASERVICELOGON
set print=
call :PRINTSCREEN
echo - Checking the password...
sc start kopia >nul
ping -n 5 127.0.0.1>nul
for /F "tokens=3 delims=: " %%H in ('sc query "Kopia" ^| findstr /c:"        STATE" /c:"Service FAILED"') do (
  if /I "%%H" NEQ "RUNNING" (
    echo - [ERROR] %logged_user%'s password is incorrect
    goto :TRYCONFIGKOPIASERVICELOGON
  )
)
goto :DONECONFIGKOPIASERVICELOGON

:TRYCONFIGKOPIASERVICELOGON
choice /C YN /N /M "!nl!.%BS%  Try Again? Press Y for Yes, N for No: "
if %ERRORLEVEL% NEQ 1 (
  goto :CONFIGKOPIASERVICELOGON
)

:DONECONFIGKOPIASERVICELOGON
sc stop kopia >nul
sc config Kopia start=auto
set print=- The service has been configured to log in as the !logged_user! account!nl!- Kopia Service set to start automatically
call :PRINTSCREEN

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set print=!nl!!Bar!!nl!Creating TLS Certificate!!nl!
call :PRINTSCREEN
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:CREATESSLCERT

:CREATEROOTCA
%~dp0tools\openssl\openssl.exe genrsa ^
  -out %~dp0tls\kopia.ca.key 2048

%~dp0tools\openssl\openssl.exe req ^
  -x509 -new -nodes ^
  -key %~dp0tls\kopia.ca.key -sha256 -days 3650 ^
  -out %~dp0tls\kopia.ca.pem ^
  -config %~dp0configs\tls.conf  >nul
if exist "%~dp0tls\kopia.ca.pem" (
  set print=- Root CA certificate has been created!nl!  ^> Saved to %~dp0tls\kopia.ca.pem
  call :PRINTSCREEN
  goto :CREATESSL
) else (
  echo - [ERROR] The Root CA certificate file was not created. Check for file system permissions and retry.
  goto :TRYCREATEROOTCA
)
:TRYCREATEROOTCA
choice /C YN /N /M "!nl!.%BS%  Retry? Press Y for Yes, N for No: "
if %ERRORLEVEL% EQU 1 (
  set print=
  call :PRINTSCREEN
  goto :CREATEROOTCA
)
if %ERRORLEVEL% EQU 2 (
  set print=- [ERROR] The Root CA certificate file was not created. Check for file system permissions and retry.
  call :PRINTSCREEN
  set script_error=1
  goto :FINISH
)


:CREATESSL
%~dp0tools\openssl\openssl.exe genrsa ^
  -out %~dp0tls\kopia.key 2048

%~dp0tools\openssl\openssl.exe req ^
  -new -config %~dp0configs\tls.conf ^
  -key %~dp0tls\kopia.key ^
  -out %~dp0tls\kopia.csr >nul 2>&1

%~dp0tools\openssl\openssl.exe x509 -req ^
  -in %~dp0tls\kopia.csr ^
  -CA %~dp0tls\kopia.ca.pem ^
  -CAkey %~dp0tls\kopia.ca.key ^
  -CAcreateserial ^
  -out %~dp0tls\kopia.crt -days 3650 -sha256 >nul 2>&1
if exist "%~dp0tls\kopia.crt" (
  set print=- SSL certificate for Kopia has been created!nl!  ^> Saved to %~dp0tls\kopia.key!nl!  ^> Saved to %~dp0tls\kopia.crt
  call :PRINTSCREEN
  goto :PRINTSSLSHA256
) else (
  echo - [ERROR] The SSL certificate file was not created. Check for file system permissions and retry.
  goto :TRYCREATESSL
)
:TRYCREATESSL
choice /C YN /N /M "!nl!.%BS%  Retry? Press Y for Yes, N for No: "
if %ERRORLEVEL% EQU 1 (
  set print=
  call :PRINTSCREEN
  goto :CREATESSL
)
if %ERRORLEVEL% EQU 2 (
  set print=- [ERROR] The SSL certificate file was not created. Check for file system permissions and retry.
  call :PRINTSCREEN
  set script_error=1
  goto :FINISH
)

:PRINTSSLSHA256
set sha256_cmd=%~dp0tools\openssl\openssl.exe x509 -noout -fingerprint -sha256 -inform pem -in "%~dp0tls\kopia.crt"
for /f "delims=^= tokens=2 usebackq" %%G in (`!sha256_cmd!`) do (
  echo SERVER CERT SHA256: %%G > "%~dp0tls\SHA256.txt"
  set print=- SERVER CERT SHA256: %%G!nl!  ^> Saved to %~dp0tls\SHA256.txt
  call :PRINTSCREEN
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set print=!nl!!Bar!!nl!Set Kopia WebUI password!nl!!nl!
set print=!print!- This script sets up the Kopia service to use the default account 'kopia' for logging into the Web UI.
call :PRINTSCREEN
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:SETWEBUIPASS

set /p kopia_pass=.%BS%  ^> Enter the password for Kopia WebUI account: 
echo .%BS%  ^> Kopia WebUI account: kopia!nl!  ^> Kopia WebUI password: !kopia_pass!
choice /C YN /N /M "!nl!.%BS%  Confirm? Press Y for Yes, N for No: "
if %ERRORLEVEL% EQU 1 (
  %~dp0tools\htpasswd.exe -cb -B "%~dp0configs\.htpasswd" kopia "!kopia_pass!" >nul 2>&1
  goto :TESTWEBUIPASS
)
if %ERRORLEVEL% EQU 2 (
  set kopia_pass=
  cls
  set print=
  call :PRINTSCREEN
  goto :SETWEBUIPASS
)
:TESTWEBUIPASS
%~dp0tools\htpasswd.exe -vb -B "%~dp0configs\.htpasswd" kopia "!kopia_pass!" >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
  echo !nl!- [ERROR] Something went wrong with the htpasswd file creation..
  goto :TRYSETWEBUIPASS
) else (
  set print=- Web UI login password has been created.
  call :PRINTSCREEN
  goto :SETUPREPO
)
:TRYSETWEBUIPASS
choice /C YN /N /M "!nl!.%BS%  Try again? Press Y for Yes, N for No: "
if %ERRORLEVEL% EQU 1 (
  set kopia_pass=
  cls  
  set print=
  call :PRINTSCREEN
  goto :SETWEBUIPASS
)
if %ERRORLEVEL% EQU 2 (
  set kopia_pass=
  cls
  set print=- [ERROR] Something went wrong with the htpasswd file creation...
  call :PRINTSCREEN
  set script_error=1
  goto :FINISH
)


:SETUPREPO
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set print=!nl!!Bar!!nl!Setup Kopia Repository with Rclone!nl!
call :PRINTSCREEN
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

choice /C YN /N /M ".%BS%  Do you want to setup Repository now? Press Y for Yes, N for No: "
if %ERRORLEVEL% NEQ 1 (
  set print=- Repository setup has been skipped. You can configure it later using the Web UI or CLI.
  call :PRINTSCREEN
  goto STARTKOPIA
)

:SETUPRCLONE
call :SAVESCREEN
:RESETUPRCLONE
call :LOADSCREEN
echo.  This script sets up Kopia to work with the bundled Rclone tool
echo.  The Rclone config file is saved in "%~dp0configs\rclone.conf"
choice /C YN /N /M "!nl!.%BS%  Do you want to setup Rclone now? Press Y for Yes, N for No: "
if %ERRORLEVEL% NEQ 1 (
  set print=- Rclone configuration has been skipped. The script will proceed with the existing configuration.
  call :PRINTSCREEN
  goto :TESTRCLONE
)
if %ERRORLEVEL% EQU 1 (
  cls
  echo !nl!!title!Once you have completed the Rclone setup, select "q) Quit config" to return!nl!!nl!!bar!!nl!
  %~dp0tools\rclone.exe config --config %~dp0configs\rclone.conf  
  set print=
  call :PRINTSCREEN
)

:TESTRCLONE
echo - Setting up the remote path...
set "rclone_output=%TEMP%\%~n0.tmp"
set /p rclone_remote=.%BS%  ^> Enter Rclone remote folder (remote:path\to\destination\folder): 
if "!rclone_remote!" == "" (
  echo.  ^> [ERROR] Cannot use an empty remote path.
  goto :TESTRCLONEFAIL
)
set rclone_test=%~dp0tools\rclone.exe test info --all "%rclone_remote%" --config "%~dp0configs\rclone.conf"
echo.  ^> Checking remote path "%rclone_remote%"...
%rclone_test% 2> "%rclone_output%" >nul

if %ERRORLEVEL% EQU 0 (
  set print=- The remote path "%rclone_remote%" will be used to set up the repository.
  call :PRINTSCREEN
  goto :SETUPREPOWITHRCLONE
)
if %ERRORLEVEL% NEQ 0 (
  for /f "tokens=2* usebackq" %%G in (`findstr /c:"Failed to" /c:"couldn't" "%rclone_output%"`) do (
    echo.  ^> %%H
  )
)
:TESTRCLONEFAIL
choice /C YN /N /M "!nl!.%BS%  Try again? Press Y for Yes, N for No: "
if %ERRORLEVEL% NEQ 1 (
  set print=- [ERROR] Rclone could not set up remote "%rclone_remote%" as the repository for Kopia.
  set print=!print!!nl!- Repository setup has been canceled.
  call :PRINTSCREEN
  goto :STARTKOPIA
)
if %ERRORLEVEL% EQU 1 (
  goto :RESETUPRCLONE
)

:SETUPREPOWITHRCLONE
sc stop Kopia >nul

echo.  ^> Setting up the repository...!nl!
:KOPIACREATEREPO
%~dp0kopia.exe repository create rclone ^
  --config-file "%~dp0configs\repository.config" ^
  --rclone-exe "%~dp0tools\rclone.exe" ^
  --rclone-args="--config=%~dp0configs\rclone.conf" ^
  --remote-path "%rclone_remote%" ^
  --no-check-for-updates ^
  --ecc-overhead-percent 5

if %ERRORLEVEL% EQU 1 (
  echo !nl!  ^> [ERROR] An error occurred while setting up the repository.
  echo .%BS%  ^> The repository may have been set up previously; attempting to reconnect...!nl!
  goto :KOPIACONNECTREPO
) else (
  goto :REPOCONNECTED
)

:KOPIACONNECTREPO
%~dp0kopia.exe repository connect rclone ^
  --config-file "%~dp0configs\repository.config" ^
  --rclone-exe "%~dp0tools\rclone.exe" ^
  --rclone-args="--config=%~dp0configs\rclone.conf" ^
  --remote-path "%rclone_remote%" ^
  --no-check-for-updates
if %ERRORLEVEL% EQU 1 (
  echo !nl!  ^> [ERROR] An error occurred while connecting to the repository.
  echo .%BS%  ^> Incorrect password or the remote path cannot be set up as the repository.!nl!
  goto :TESTRCLONEFAIL
) else (
  goto :REPOCONNECTED
)

:REPOCONNECTED
set print=- Repository for Kopia has been successfully set up at the path "%rclone_remote%"
call :PRINTSCREEN

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
set print=!nl!!Bar!!nl!Starting up the Kopia service!nl!
call :PRINTSCREEN
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:STARTKOPIA

echo ^> Starting the Kopia service...
sc start Kopia >nul
ping -n 5 127.0.0.1>nul
for /F "tokens=3 delims=: " %%H in ('sc query "Kopia" ^| findstr /c:"        STATE" /c:"Service FAILED"') do (
  if /I "%%H" NEQ "RUNNING" (
    echo - [ERROR]  An error occurred while starting the Kopia service.
    goto :TRYSTARTKOPIA
  )
)

goto :DONESTARTKOPIA

:TRYSTARTKOPIA
choice /C YN /N /M "!nl!.%BS%  Try Again? Press Y for Yes, N for No: "
if %ERRORLEVEL% EQU 1 (
  set print=
  call :PRINTSCREEN
  goto :STARTKOPIA
)
if %ERRORLEVEL% EQU 2 (
  set print=- [ERROR] An error occurred while starting the Kopia service.
  set print=!print!!nl!- Please check the logs in the folder '%~dp0logs\' for more details.
  call :PRINTSCREEN
  set script_error=1
  goto :FINISH
)

:DONESTARTKOPIA
set print=- The Kopia service has started. You can access the WebUI at 127.0.0.1:51515
call :PRINTSCREEN

:FINISH
set print=!nl!!nl!The script has finished running.^^!
if %script_error% EQU 1 (
set print=!print!!nl!An error was encountered. Verify account permissions and resolve any conflicts, then attempt to run the script again.
)
call :PRINTSCREEN
goto EXIT

:SAVESCREEN
set savedscreen=!screen!
goto :eof

:LOADSCREEN
set screen=!savedscreen!
set print=
call :PRINTSCREEN
goto :eof

:PRINTSCREEN
cls
if "!print!" == "" (
  set print=!print!
) else (
  set print=!nl!!print!
)
set screen=!screen!!print!
echo !screen!
goto :eof

:EXIT
del "%rclone_output%" >nul
echo:
pause