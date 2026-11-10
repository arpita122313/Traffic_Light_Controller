@echo off
REM =============================================================================
REM Automated GitHub Repository Publisher
REM Project: Four-Way Traffic Light Controller
REM =============================================================================

echo ===========================================================================
echo   PUBLISH TRAFFIC LIGHT CONTROLLER TO GITHUB
echo ===========================================================================
echo.

where git >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed or not in system PATH.
    echo Please install Git from https://git-scm.com/ and try again.
    pause
    exit /b
)

if not exist .git (
    echo [INFO] Initializing new Git repository...
    git init
    git branch -M main
)

echo [INFO] Staging all project files...
git add .

echo [INFO] Committing project files...
git commit -m "feat: complete four-way traffic light controller in Verilog HDL with FSM, self-checking testbench, Vivado synthesis, and documentation"

echo.
echo ===========================================================================
echo Please enter your GitHub Repository Remote URL
echo Example: https://github.com/your-username/Traffic_Light_Controller.git
echo ===========================================================================
set /p REPO_URL="Repository URL: "

if "%REPO_URL%"=="" (
    echo [WARNING] No URL provided. Git commit created locally.
    pause
    exit /b
)

git remote remove origin >nul 2>nul
git remote add origin %REPO_URL%

echo [INFO] Pushing code to GitHub main branch...
git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] Project successfully published to %REPO_URL%!
) else (
    echo.
    echo [ERROR] Push failed. Please verify your repository URL and credentials.
)

pause
