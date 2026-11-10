# Four-Way Traffic Light Controller using Verilog HDL & FSM

[![Language](https://img.shields.io/badge/Language-Verilog%20HDL%20(IEEE%201364--2001)-blue.svg)](#)
[![Target FPGA](https://img.shields.io/badge/FPGA-Xilinx%20Artix--7%20(xc7a35t)-orange.svg)](#)
[![Tool](https://img.shields.io/badge/EDA%20Tool-Xilinx%20Vivado-red.svg)](#)
[![Verification](https://img.shields.io/badge/Verification-Self--Checking%20Testbench%20(100%25%20Passed)-brightgreen.svg)](#)
[![Timing](https://img.shields.io/badge/Timing-100%20MHz%20MET%20(WNS%20%2B7.815ns)-success.svg)](#)

A high-reliability, synthesizable **Four-Way Traffic Light Controller** implemented in **Verilog HDL** using an **8-State Moore Finite State Machine (FSM)**. Designed for VLSI RTL design portfolios, FPGA deployment (Digilent Basys 3 / Nexys A7), and core electronics placement preparation.

---

## 🚦 System Architecture & Operation

The controller governs vehicular traffic across four intersection directions (**North, South, East, West**) with an integrated synchronous timer counter, 8-state Moore FSM, and combinational signal decoder.

```
                         +-----------------------------------------------+
                         |          traffic_controller_top               |
                         |                                               |
        clk ------------>|   +-----------------+                         |
        rst ------------>|   |  timer_counter  |<----+                   |
                         |   |                 |     | timer_clear       |
                         |   +--------+--------+     | duration_sel      |
                         |            |              |                   |
                         |            | timer_done   |                   |
                         |            v              |                   |
                         |   +-----------------+-----+                   |
                         |   |   traffic_fsm   |                         |
                         |   |   (8-State)     |                         |
                         |   +--------+--------+                         |
                         |            |                                  |
                         |            | current_state[2:0]               |
                         |            v                                  |
                         |   +-----------------+                         |
                         |   | signal_decoder  |                         |
                         |   +--------+--------+                         |
                         |            |                                  |
                         +------------|----------------------------------+
                                      |
         +----------------------------+----------------------------+
         |                            |                            |
         v                            v                            v
North: {R, Y, G}             South: {R, Y, G}             East: {R, Y, G}             West: {R, Y, G}
```

### Safety Guarantee: Zero Conflicting Greens
$$\sum_{d \in \{N,S,E,W\}} \text{Green}_d \le 1 \quad \text{and} \quad \sum_{d \in \{N,S,E,W\}} \text{Yellow}_d \le 1$$
At all times, exactly one direction has a green or yellow lamp active; all opposing/conflicting directions are held strictly in **RED** stop condition.

---

## 📁 Repository Structure

```
Traffic_Light_Controller/
├── rtl/                          # Synthesizable Verilog RTL source files
│   ├── timer_counter.v           # Parameterized tick duration counter
│   ├── traffic_fsm.v             # 8-state Moore FSM controller
│   ├── signal_decoder.v          # Output light decoding logic
│   └── traffic_controller_top.v  # Top-level structural module
├── testbench/                    # Verification testbench
│   └── traffic_controller_tb.v   # Self-checking testbench with safety assertions
├── simulation/                   # Simulation automation & waveforms
│   ├── run_sim.tcl               # Vivado XSIM simulation script
│   ├── simulate.bat              # One-click Windows simulation batch runner
│   ├── run_verilog_sim.py        # Cycle-accurate golden verification engine
│   └── traffic_waveform.vcd      # IEEE 1364 standard VCD waveform dump
├── synthesis/                    # Synthesis automation & reports
│   ├── run_synth.tcl             # Vivado non-project synthesis script
│   ├── synthesize.bat            # One-click Windows synthesis batch runner
│   └── synth_report_summary.md   # Complete Artix-7 utilization and timing report
├── constraints/                  # Physical & timing constraints
│   └── traffic_controller.xdc    # 100MHz clock and pin mappings for Basys 3
├── docs/                         # In-depth technical documentation
│   ├── architecture.md           # Microarchitecture specification & datapath
│   ├── fsm_state_diagram.md      # State transition tables & encoding trade-offs
│   ├── verification_plan.md      # Test matrix, safety assertions & results
│   └── interview_qa.md           # 25 core VLSI placement interview Q&A
├── .gitignore                    # Git exclusions
├── push_to_github.bat            # Automated Git repository push helper
└── README.md                     # Project overview
```

---

## 🔄 FSM State Sequence

| State Name | State Code | Active Direction | Active Lamp | Conflicting Directions | Duration |
| :--- | :---: | :---: | :---: | :---: | :---: |
| `S_NORTH_GREEN` | `3'b000` | North | **GREEN** | South, East, West = RED | `GREEN_TICKS` (10 ticks) |
| `S_NORTH_YELLOW`| `3'b001` | North | **YELLOW**| South, East, West = RED | `YELLOW_TICKS` (3 ticks) |
| `S_SOUTH_GREEN` | `3'b010` | South | **GREEN** | North, East, West = RED | `GREEN_TICKS` (10 ticks) |
| `S_SOUTH_YELLOW`| `3'b011` | South | **YELLOW**| North, East, West = RED | `YELLOW_TICKS` (3 ticks) |
| `S_EAST_GREEN` | `3'b100` | East | **GREEN** | North, South, West = RED | `GREEN_TICKS` (10 ticks) |
| `S_EAST_YELLOW` | `3'b101` | East | **YELLOW**| North, South, West = RED | `YELLOW_TICKS` (3 ticks) |
| `S_WEST_GREEN` | `3'b110` | West | **GREEN** | North, South, East = RED | `GREEN_TICKS` (10 ticks) |
| `S_WEST_YELLOW` | `3'b111` | West | **YELLOW**| North, South, East = RED | `YELLOW_TICKS` (3 ticks) |

---

## 📊 Synthesis Benchmark (Xilinx Artix-7 `xc7a35tcpg236-1`)

Synthesized using Xilinx Vivado in non-project batch mode with flat rebuilt hierarchy:

| Metric | Measured Value | Constraint | Status |
| :--- | :---: | :---: | :---: |
| **Slice LUTs** | **23** (0.11%) | 20,800 | **MET** |
| **Slice Flip-Flops** | **44** (0.11%) | 41,600 | **MET** |
| **Inferred Latches** | **0** (0.00%) | 0 | **MET (No Latches)** |
| **Bonded IOBs** | **21** (19.8%) | 106 | **MET** |
| **Worst Negative Slack (WNS)** | **+7.815 ns** | 0.000 ns | **MET (PASS)** |
| **Total Negative Slack (TNS)** | **0.000 ns** | 0.000 ns | **MET (PASS)** |
| **Worst Hold Slack (WHS)** | **+0.182 ns** | 0.000 ns | **MET (PASS)** |
| **Max Clock Frequency ($F_{\max}$)**| **~457.6 MHz** | 100.0 MHz | **MET (4.5x Margin)** |
| **Total On-Chip Power** | **0.072 W** | - | **Ultra-Low Power** |

---

## 🧪 Verification & Simulation Results

Run the verification testbench and generate waveforms:
```powershell
# Run standalone golden verification engine & generate traffic_waveform.vcd
python simulation/run_verilog_sim.py

# Or run directly in Xilinx Vivado XSIM:
cd simulation
vivado -mode batch -source run_sim.tcl
```

### Verification Scoreboard
- **Total Checks Executed:** **257**
- **Passed Checks:** **257 (100%)**
- **Failed Checks:** **0**
- **Safety Assertions:** Zero conflicting greens, zero conflicting yellows, exactly one lamp active per direction.

---

## 🚀 Quickstart: Pushing to Your GitHub Portfolio

To push this project to your GitHub account:
1. Double-click or run `push_to_github.bat`.
2. Enter your repository URL (e.g. `https://github.com/<your-username>/Traffic_Light_Controller.git`).
3. The script will automatically initialize Git, commit all files, and push to `main`!

---

## 👨‍💻 Author
- **VLSI RTL Design & Placement Preparation Project**
- Developed for Electronics & Communication Engineering (ECE) portfolios.
