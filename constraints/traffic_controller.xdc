## =============================================================================
## Project     : Four-Way Traffic Light Controller
## File        : traffic_controller.xdc
## Target Board: Digilent Basys 3 / Nexys A7 (Xilinx Artix-7 xc7a35tcpg236-1)
## Standard    : SDC / Vivado Design Constraints (XDC)
## =============================================================================

## -----------------------------------------------------------------------------
## Clock Signal (100 MHz Master Oscillator)
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5.000} [get_ports clk]

## -----------------------------------------------------------------------------
## Reset Pushbutton (Active-High Center Button btnC)
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## -----------------------------------------------------------------------------
## North Traffic Lights (LED 0, 1, 2)
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN U16 [get_ports north_green]
set_property IOSTANDARD LVCMOS33 [get_ports north_green]

set_property PACKAGE_PIN E19 [get_ports north_yellow]
set_property IOSTANDARD LVCMOS33 [get_ports north_yellow]

set_property PACKAGE_PIN U19 [get_ports north_red]
set_property IOSTANDARD LVCMOS33 [get_ports north_red]

## -----------------------------------------------------------------------------
## South Traffic Lights (LED 3, 4, 5)
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN V19 [get_ports south_green]
set_property IOSTANDARD LVCMOS33 [get_ports south_green]

set_property PACKAGE_PIN W18 [get_ports south_yellow]
set_property IOSTANDARD LVCMOS33 [get_ports south_yellow]

set_property PACKAGE_PIN U15 [get_ports south_red]
set_property IOSTANDARD LVCMOS33 [get_ports south_red]

## -----------------------------------------------------------------------------
## East Traffic Lights (LED 6, 7, 8)
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN U14 [get_ports east_green]
set_property IOSTANDARD LVCMOS33 [get_ports east_green]

set_property PACKAGE_PIN V14 [get_ports east_yellow]
set_property IOSTANDARD LVCMOS33 [get_ports east_yellow]

set_property PACKAGE_PIN V13 [get_ports east_red]
set_property IOSTANDARD LVCMOS33 [get_ports east_red]

## -----------------------------------------------------------------------------
## West Traffic Lights (LED 9, 10, 11)
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN V3  [get_ports west_green]
set_property IOSTANDARD LVCMOS33 [get_ports west_green]

set_property PACKAGE_PIN W3  [get_ports west_yellow]
set_property IOSTANDARD LVCMOS33 [get_ports west_yellow]

set_property PACKAGE_PIN U3  [get_ports west_red]
set_property IOSTANDARD LVCMOS33 [get_ports west_red]

## -----------------------------------------------------------------------------
## State Diagnostic Indicators (LED 13, 14, 15)
## -----------------------------------------------------------------------------
set_property PACKAGE_PIN N3  [get_ports {state_out[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[0]}]

set_property PACKAGE_PIN P1  [get_ports {state_out[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[1]}]

set_property PACKAGE_PIN L1  [get_ports {state_out[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {state_out[2]}]

## -----------------------------------------------------------------------------
## Configuration and Voltage Bank Settings
## -----------------------------------------------------------------------------
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
