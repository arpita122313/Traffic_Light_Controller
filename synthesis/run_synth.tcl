# =============================================================================
# Vivado Non-Project Mode Synthesis Script
# Project : Four-Way Traffic Light Controller
# Target  : Xilinx Artix-7 (xc7a35tcpg236-1)
# =============================================================================

set_param general.maxThreads 4
set synth_dir [file normalize [file dirname [info script]]]
set root_dir [file normalize $synth_dir/..]
cd $synth_dir

puts "======================================================================"
puts "  Synthesizing Traffic Light Controller for Xilinx Artix-7 FPGA"
puts "======================================================================"

# Read synthesizable RTL sources
read_verilog $root_dir/rtl/timer_counter.v
read_verilog $root_dir/rtl/traffic_fsm.v
read_verilog $root_dir/rtl/signal_decoder.v
read_verilog $root_dir/rtl/traffic_controller_top.v

# Read timing and physical constraints
read_xdc $root_dir/constraints/traffic_controller.xdc

# Run synthesis (Hardware mode with clock divider active)
synth_design -top traffic_controller_top -part xc7a35tcpg236-1 -generic SIMULATION_MODE=0 -flatten_hierarchy rebuilt

# Generate detailed reports
report_utilization -file util_report.txt
report_timing_summary -file timing_report.txt
report_power -file power_report.txt
report_drc -file drc_report.txt

puts "======================================================================"
puts "  Synthesis completed successfully. Reports saved to synthesis/"
puts "======================================================================"
exit
