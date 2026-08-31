@echo off
setlocal
title easySVA Start

set "DISTRO=Ubuntu-22.04-easySVA"
set "URL=http://localhost/"

echo [1/4] Starting the easySVA WSL environment...
wsl.exe -d "%DISTRO%" -u root -- true >nul 2>&1
if errorlevel 1 goto :wsl_error

echo [2/4] Keeping WSL alive in the background...
wsl.exe -d "%DISTRO%" -u root -- sh -lc "pgrep -f '^sleep infinity$' >/dev/null" >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath $env:WINDIR\System32\wsl.exe -ArgumentList @('-d','%DISTRO%','-u','root','--','sleep','infinity') -WindowStyle Hidden" >nul 2>&1
)

echo [3/4] Starting database, backend, media and analyzer services...
wsl.exe -d "%DISTRO%" -u root -- systemctl start mariadb redis-server nginx easysva-backend easysva-media easysva-analyzer easysva-rtsp-simulator >nul 2>&1
if errorlevel 1 goto :service_error

echo [4/4] Waiting for the backend API...
set /a WAIT_COUNT=0

:wait_backend
curl.exe --fail --silent --output NUL --max-time 3 http://localhost/prod-api/captchaImage
if not errorlevel 1 goto :ready
set /a WAIT_COUNT+=1
if %WAIT_COUNT% GEQ 30 goto :backend_timeout
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

:backend_timeout
echo.
echo ERROR: The backend API did not become ready within 30 seconds.
echo Refresh %URL% later or inspect the easysva-backend logs.
pause
exit /b 1
