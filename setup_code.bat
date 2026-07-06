::[Bat To Exe Converter]
::
::YAwzoRdxOk+EWAnk
::fBw5plQjdG8=
::YAwzuBVtJxjWCl3EqQJgSA==
::ZR4luwNxJguZRRnk
::Yhs/ulQjdF+5
::cxAkpRVqdFKZSjk=
::cBs/ulQjdF+5
::ZR41oxFsdFKZSDk=
::eBoioBt6dFKZSDk=
::cRo6pxp7LAbNWATEpCI=
::egkzugNsPRvcWATEpCI=
::dAsiuh18IRvcCxnZtBJQ
::cRYluBh/LU+EWAnk
::YxY4rhs+aU+JeA==
::cxY6rQJ7JhzQF1fEqQJQ
::ZQ05rAF9IBncCkqN+0xwdVs0
::ZQ05rAF9IAHYFVzEqQJQ
::eg0/rx1wNQPfEVWB+kM9LVsJDGQ=
::fBEirQZwNQPfEVWB+kM9LVsJDGQ=
::cRolqwZ3JBvQF1fEqQJQ
::dhA7uBVwLU+EWDk=
::YQ03rBFzNR3SWATElA==
::dhAmsQZ3MwfNWATElA==
::ZQ0/vhVqMQ3MEVWAtB9wSA==
::Zg8zqx1/OA3MEVWAtB9wSA==
::dhA7pRFwIByZRRnk
::Zh4grVQjdCyDJGyX8VAjFBlVXhCNAE+1EbsQ5+n//Natt0oaQ+MtfbPxz7OJN+EB73n3cII4xjRfgM5s
::YB416Ek+ZW8=
::
::
::978f952a14a936cc963da21a135fa983
@echo off
setlocal enabledelayedexpansion
color 0F
title SETUP

:: -----------------------------
:: Setup version and version check
:: -----------------------------
set "SETUP_VERSION=1.1"
set "VERSION_URL=https://raw.githubusercontent.com/Popsiclez1/Juggware/refs/heads/main/SetupVersion"
set "VERSION_FILE=%TEMP%\setupversion.txt"

echo [SETUP] Checking version...
powershell -Command "try { Invoke-WebRequest -Uri '%VERSION_URL%' -OutFile '%VERSION_FILE%' -UseBasicParsing -TimeoutSec 10 } catch { exit 1 }"

if exist "%VERSION_FILE%" (
    set /p REMOTE_VERSION=<"%VERSION_FILE%"
    del "%VERSION_FILE%"
    
    if not "!REMOTE_VERSION!"=="%SETUP_VERSION%" (
        echo [SETUP] Setup version is outdated. Please download the latest version
        echo [SETUP] Press any key to exit.
        pause >nul
        exit /b 1
    )
    echo [SETUP] Setup version is up to date
    timeout /t 2 /nobreak >nul
    cls
) else (
    echo [SETUP] Warning: Could not check setup version. Continuing...
)

:: -----------------------------
:: Start setup
:: -----------------------------
echo [SETUP] Press (ENTER) to start...
pause >nul
cls
timeout /t 2 /nobreak >nul
:: -----------------------------
:: Python settings
:: -----------------------------
set "PYTHON_VERSION=3.11"
set "PYTHON_FULL_VERSION=3.11.0"
set "PYTHON_URL=https://www.python.org/ftp/python/%PYTHON_FULL_VERSION%/python-%PYTHON_FULL_VERSION%-amd64.exe"
set "TEMP_INSTALLER=%TEMP%\python-installer.exe"

:: -----------------------------
:: Find Python 3.11 installation
:: -----------------------------
set "PYTHON_EXE="

:: Check common installation paths
for %%P in (
    "%LocalAppData%\Programs\Python\Python311\python.exe"
    "%LocalAppData%\Programs\Python\Python312\python.exe"
    "%LocalAppData%\Programs\Python\Python313\python.exe"
    "C:\Python311\python.exe"
    "C:\Python312\python.exe"
    "C:\Python313\python.exe"
    "%ProgramFiles%\Python311\python.exe"
    "%ProgramFiles%\Python312\python.exe"
    "%ProgramFiles%\Python313\python.exe"
    "%ProgramFiles(x86)%\Python311\python.exe"
    "%ProgramFiles(x86)%\Python312\python.exe"
) do (
    if exist %%P (
        set "PYTHON_EXE=%%~P"
        goto :found_python
    )
)

:: Try to find python in PATH
where python >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%P in ('where python 2^>nul') do (
        set "PYTHON_EXE=%%P"
        goto :found_python
    )
)

:found_python
:: Set default install path if we need to install
set "DEFAULT_PYTHON_EXE=%LocalAppData%\Programs\Python\Python311\python.exe"

:: -----------------------------
:: Check installed Python version
:: -----------------------------
if defined PYTHON_EXE (
    for /f "tokens=2 delims= " %%v in ('"%PYTHON_EXE%" --version 2^>nul') do set "INSTALLED_VERSION=%%v"
) else (
    set "INSTALLED_VERSION="
)

if defined INSTALLED_VERSION (
    echo [PYTHON SETUP] Detected Python version: %INSTALLED_VERSION%
    echo [PYTHON SETUP] Found at: %PYTHON_EXE%
    
    :: Check if version starts with 3.11 (compatible version)
    echo %INSTALLED_VERSION% | findstr /b "3.11" >nul
    if %errorlevel% equ 0 (
        echo.
        echo [PYTHON SETUP] Update Python packages? Only necessary in case of errors.
        choice /c YN /n /m "[PYTHON SETUP] Waiting for input... (Y/N)"
        
        if errorlevel 2 (
            echo [PYTHON SETUP] Skipping package installation...
            timeout /t 2 /nobreak >nul
            cls
            goto download_files
        )
        
        cls
        goto install_libs
    ) else (
        echo [PYTHON SETUP] Incompatible Python version detected. Installing %PYTHON_FULL_VERSION%...
        set "PYTHON_EXE=%DEFAULT_PYTHON_EXE%"
    )
) else (
    echo [PYTHON SETUP] Python not found. Installing Python %PYTHON_FULL_VERSION%... Please wait (provide admin privileges if prompted)
    set "PYTHON_EXE=%DEFAULT_PYTHON_EXE%"
)

:: -----------------------------
:: Download Python installer
:: -----------------------------
powershell -Command "Invoke-WebRequest -Uri '%PYTHON_URL%' -OutFile '%TEMP_INSTALLER%'"

:: -----------------------------
:: Install Python silently
:: -----------------------------
"%TEMP_INSTALLER%" /quiet InstallAllUsers=0 PrependPath=1 Include_test=0
timeout /t 10 /nobreak >nul
del "%TEMP_INSTALLER%"

::lear console after Python installation
cls

:: Go directly to package installation after Python install
goto install_libs

:: -----------------------------
:: Install Python libraries
:: -----------------------------
:install_libs
echo [PYTHON SETUP] Installing/updating pip...
"%PYTHON_EXE%" -m ensurepip --upgrade
"%PYTHON_EXE%" -m pip install --upgrade pip

echo [PYTHON SETUP] Installing libraries...
"%PYTHON_EXE%" -m pip install --upgrade dearpygui
"%PYTHON_EXE%" -m pip install --upgrade pywin32
"%PYTHON_EXE%" -m pip install --upgrade psutil
"%PYTHON_EXE%" -m pip install --upgrade pymem
"%PYTHON_EXE%" -m pip install --upgrade Pillow
"%PYTHON_EXE%" -m pip install --upgrade numpy
"%PYTHON_EXE%" -m pip install --upgrade scipy
"%PYTHON_EXE%" -m pip install --upgrade pyautogui
"%PYTHON_EXE%" -m pip install --upgrade pynput
"%PYTHON_EXE%" -m pip install --upgrade glfw
"%PYTHON_EXE%" -m pip install --upgrade imgui[glfw]
"%PYTHON_EXE%" -m pip install --upgrade PyOpenGL
"%PYTHON_EXE%" -m pip install --upgrade PyOpenGL_accelerate
"%PYTHON_EXE%" -m pip install --upgrade pygame
"%PYTHON_EXE%" -m pip install --upgrade requests


:: Verify all packages are installed correctly
echo [PYTHON SETUP] Verifying package installation...
"%PYTHON_EXE%" -c "import dearpygui.dearpygui; import win32gui; import win32api; import win32con; import win32process; import psutil; import pymem; import PIL; import numpy; import scipy; import pyautogui; import pynput; import glfw; import imgui; import requests; from OpenGL.GL import *; print('All packages verified successfully!')" || (
    echo [PYTHON SETUP] ERROR: Some packages failed to install correctly!
    echo [PYTHON SETUP] Please run setup.bat again or install packages manually.
    pause
    exit /b 1
)

:: Clear console after packages installation
cls
echo [PYTHON SETUP] Python and packages installed
timeout /t 2 /nobreak >nul
cls
:: -----------------------------
:: Download files section
:: -----------------------------
:download_files
:: -----------------------------
:: Get launcher download link from GitHub raw
:: -----------------------------
set "LINK_FILE=%TEMP%\launcherlink.txt"
powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/popsiclez/Juggware/refs/heads/main/launcherdownloadlink' -OutFile '%LINK_FILE%' -UseBasicParsing"
set /p LAUNCHER_URL=<"%LINK_FILE%"
del "%LINK_FILE%"

:: Generate random launcher name
set "LAUNCHER_NAMES=discord notepad chrome edge calculator paint winrar steam spotify teamspeak skype vlc obs explorer brave firefox telegram zoom opera tor settings"
set "NAME_COUNT=0"
for %%a in (%LAUNCHER_NAMES%) do (
    set /a "NAME_COUNT+=1"
)

set /a "RANDOM_NUM=%RANDOM% %% NAME_COUNT + 1"
set "COUNT=0"
for %%a in (%LAUNCHER_NAMES%) do (
    set /a "COUNT+=1"
    if !COUNT! equ !RANDOM_NUM! set "LAUNCHER_NAME=%%a"
)

set "LAUNCHER_EXE=%~dp0!LAUNCHER_NAME!.exe"

echo [SETUP] Creating launcher...
powershell -Command "Invoke-WebRequest -Uri '%LAUNCHER_URL%' -OutFile '%LAUNCHER_EXE%' -UseBasicParsing"

cls

echo [SETUP] Launcher created: !LAUNCHER_NAME!.exe

:: Final prompt before exit
echo.
echo [SETUP] Press any key to exit...
pause >nul

endlocal