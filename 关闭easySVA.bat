@echo off
setlocal
title easySVA Stop

set "DISTRO=Ubuntu-22.04-easySVA"

echo [1/2] Stopping easySVA services...
wsl.exe -d "%DISTRO%" -u root -- systemctl stop easysva-rtsp-simulator easysva-analyzer easysva-media easysva-backend nginx redis-server mariadb >nul 2>&1

echo [2/2] Terminating the easySVA WSL environment...
wsl.exe --terminate "%DISTRO%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: WSL could not be terminated. Check its status manually.
    pause
    exit /b 1
)

echo easySVA is stopped. Other WSL distributions were not affected.
ping.exe -n 4 127.0.0.1 >nul
exit /b 0
