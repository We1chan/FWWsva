@echo off
setlocal
title easySVA Start

set "DISTRO=Ubuntu-22.04-easySVA"
set "URL=http://localhost/"

echo [1/5] Starting the easySVA WSL environment...
wsl.exe -d "%DISTRO%" -u root -- true >nul 2>&1
if errorlevel 1 goto :wsl_error

echo [2/5] Keeping WSL alive in the background...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0deploy\scripts\start-wsl-keepalive.ps1" -Distro "%DISTRO%" >nul 2>&1
if errorlevel 1 goto :keepalive_error

echo [3/5] Starting database, backend, media and analyzer services...
wsl.exe -d "%DISTRO%" -u root -- systemctl start mariadb redis-server nginx easysva-backend easysva-media easysva-analyzer easysva-rtsp-simulator >nul 2>&1
if errorlevel 1 goto :service_error

echo [4/5] Restoring running camera streams...
wsl.exe -d "%DISTRO%" -u root -- systemctl restart easysva-stream-restore >nul 2>&1
if errorlevel 1 goto :stream_restore_error

echo [5/5] Waiting for the backend API...
set /a WAIT_COUNT=0

:wait_backend
curl.exe --fail --silent --output NUL --max-time 3 http://localhost/prod-api/captchaImage
if not errorlevel 1 goto :ready
set /a WAIT_COUNT+=1
if %WAIT_COUNT% GEQ 120 goto :backend_timeout
ping.exe -n 2 127.0.0.1 >nul
goto :wait_backend

:ready
echo.
echo easySVA is ready. Opening %URL%
start "" "%URL%"
echo Default login: admin / admin123
ping.exe -n 4 127.0.0.1 >nul
exit /b 0

:wsl_error
echo.
echo ERROR: %DISTRO% was not found or could not be started.
pause
exit /b 1

:service_error
echo.
echo ERROR: One or more systemd services failed to start.
echo Run this in WSL for details: systemctl status easysva-backend
pause
exit /b 1

:stream_restore_error
echo.
echo ERROR: Failed to restore one or more running camera streams.
echo Run this in WSL for details: journalctl -u easysva-stream-restore -n 50
pause
exit /b 1

:keepalive_error
echo.
echo ERROR: Failed to create the WSL keepalive process.
pause
exit /b 1

:backend_timeout
echo.
echo ERROR: The backend API did not become ready within 120 seconds.
echo Refresh %URL% later or inspect the easysva-backend logs.
pause
exit /b 1
