@echo off
REM =============================================================================
REM Windows Batch Runner for Vivado Simulation
REM Project: Four-Way Traffic Light Controller
REM =============================================================================

echo ===========================================================================
echo   FOUR-WAY TRAFFIC LIGHT CONTROLLER - SIMULATION RUNNER
echo ===========================================================================

where vivado >nul 2>nul
if %errorlevel% neq 0 (
    echo [INFO] Vivado not found in system PATH.
    echo Running standalone cycle-accurate Python verification engine & VCD generator...
    echo.
    python run_verilog_sim.py
    echo.
    echo [DONE] Simulation finished. Waveforms generated in traffic_waveform.vcd.
    pause
    exit /b
)

echo [INFO] Launching Vivado XSIM batch simulation...
vivado -mode batch -source run_sim.tcl
echo.
echo [DONE] Vivado simulation complete.
pause
