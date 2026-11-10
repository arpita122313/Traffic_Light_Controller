@echo off
REM =============================================================================
REM Windows Batch Runner for Vivado Synthesis
REM Project: Four-Way Traffic Light Controller
REM =============================================================================

echo ===========================================================================
echo   FOUR-WAY TRAFFIC LIGHT CONTROLLER - VIVADO SYNTHESIS RUNNER
echo ===========================================================================

where vivado >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Vivado executable not found in system PATH.
    echo Please run this script in Vivado Command Prompt or add Vivado bin to PATH.
    echo See synthesis/synth_report_summary.md for pre-compiled utilization and timing reports.
    echo.
    pause
    exit /b
)

echo [INFO] Running Vivado non-project synthesis...
vivado -mode batch -source run_synth.tcl
echo.
echo [DONE] Synthesis finished. Check util_report.txt and timing_report.txt.
pause
