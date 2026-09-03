@echo off
setlocal
title easySVA Stop

set "DISTRO=Ubuntu-22.04-easySVA"

echo [1/3] Stopping easySVA services...
wsl.exe -d "%DISTRO%" -u root -- systemctl stop easysva-rtsp-simulator easysva-rtsp-simulator-2 easysva-rtsp-simulator-3 easysva-analyzer easysva-media easysva-backend nginx redis-server mariadb >nul 2>&1

echo [2/3] Terminating the easySVA WSL environment...
wsl.exe --terminate "%DISTRO%" >nul 2>&1
if errorlevel 1 (
    echo ERROR: WSL could not be terminated. Check its status manually.
    pause
    exit /b 1
)

echo [3/3] Releasing WSL virtual machine memory...
if /i "%~1"=="--distro-only" (
    echo easySVA is stopped. Other WSL distributions were not affected.
    echo vmmemWSL may remain because the shared WSL virtual machine was kept running.
    goto :done
)

wsl.exe --shutdown >nul 2>&1
if errorlevel 1 goto :shutdown_error

echo easySVA is stopped and vmmemWSL has been shut down.
echo Note: all WSL distributions, including Docker's WSL backend, were stopped.
goto :done

:shutdown_error
echo ERROR: WSL virtual machine shutdown failed. Run "wsl --shutdown" manually.
pause
exit /b 1

:done
ping.exe -n 4 127.0.0.1 >nul
exit /b 0
