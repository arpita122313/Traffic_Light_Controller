@echo off
setlocal enabledelayedexpansion
REM =============================================================================
REM Project       : Four-Way Traffic Light Controller
REM File          : push_to_github.bat
REM Description   : 1-Click push to https://github.com/arpita122313/Traffic_Light_Controller
REM =============================================================================

echo ==================================================================
echo   Pushing Traffic Light Controller to GitHub: arpita122313
echo ==================================================================

set "GIT_EXE=C:\Users\HP\AppData\Local\Programs\Git\cmd\git.exe"
if not exist "%GIT_EXE%" (
    where git >nul 2>nul
    if %ERRORLEVEL% equ 0 (
        set "GIT_EXE=git"
    ) else (
        echo [ERROR] Git executable not found!
        pause
        exit /b 1
    )
)

echo [*] Using Git: %GIT_EXE%

"%GIT_EXE%" status >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [*] Initializing Git repository...
    "%GIT_EXE%" init
    "%GIT_EXE%" branch -M main
)

echo [*] Staging all files...
"%GIT_EXE%" add .

echo [*] Committing changes...
"%GIT_EXE%" commit -m "feat: complete four-way traffic light controller in Verilog HDL with 8-state Moore FSM, self-checking testbench, Vivado synthesis reports, and documentation" >nul 2>nul

echo [*] Configuring remote origin...
"%GIT_EXE%" remote remove origin >nul 2>nul
"%GIT_EXE%" remote add origin https://github.com/arpita122313/Traffic_Light_Controller.git

echo.
echo [*] Pushing branch 'main' to https://github.com/arpita122313/Traffic_Light_Controller.git ...
echo (If prompted, please authorize in the GitHub login window)
echo.
"%GIT_EXE%" push -u origin main

if %ERRORLEVEL% equ 0 (
    echo.
    echo ==================================================================
    echo   SUCCESS! Your project is now live on GitHub:
    echo   https://github.com/arpita122313/Traffic_Light_Controller
    echo ==================================================================
) else (
    echo.
    echo ==================================================================
    echo   [ACTION REQUIRED]
    echo   If you received "repository not found", please ensure you have
    echo   created the empty repository on GitHub first:
    echo   ?? https://github.com/new
    echo      Repository name: Traffic_Light_Controller
    echo      Visibility     : Public
    echo.
    echo   Then simply re-run this script!
    echo ==================================================================
)

pause
