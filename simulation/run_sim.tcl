# =============================================================================
# Vivado XSIM Batch Simulation Script
# Project : Four-Way Traffic Light Controller
# Standard: Xilinx Vivado TCL
# =============================================================================

set project_dir [file normalize [file dirname [info script]]/..]
cd $project_dir

puts "Starting Vivado Behavioral Simulation..."

# Create temporary in-memory project
create_project -force -part xc7a35tcpg236-1 traffic_sim ./simulation/vivado_sim_proj

# Add RTL source files
add_files [glob ./rtl/*.v]
add_files -fileset sim_1 [glob ./testbench/*.v]

# Set testbench top
set_property top traffic_controller_tb [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Launch behavioral simulation
launch_simulation -simset sim_1 -mode behavioral

# Run simulation
run 10 us

# Generate waveform database
puts "Simulation completed successfully."
close_sim
exit
