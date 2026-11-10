# Vivado Synthesis & Timing Report Summary

**Project:** Four-Way Traffic Light Controller  
**Top-Level Module:** `traffic_controller_top`  
**Target Device:** Xilinx Artix-7 `xc7a35tcpg236-1` (Speed Grade -1)  
**EDA Tool:** Xilinx Vivado ML Edition (Non-Project Batch Synthesis Mode)  
**Constraints File:** `constraints/traffic_controller.xdc`  

---

## 1. Executive Summary

The Four-Way Traffic Light Controller RTL was synthesized targeting the Xilinx Artix-7 FPGA family. The synthesis utilized a rebuilt flat hierarchy with balanced timing optimization. 

- **Timing Status:** All user timing constraints **MET** with zero violations.
- **Worst Negative Slack (WNS):** **+7.815 ns** (Target Clock Period = 10.000 ns / 100 MHz).
- **Total Negative Slack (TNS):** **0.000 ns** (No timing violations across all endpoints).
- **Maximum Operating Frequency ($F_{\max}$):** **~457.6 MHz** (Well in excess of the 100 MHz target).
- **Total Power Consumption:** **0.072 W** (Dynamic: 0.002 W, Device Static: 0.070 W).

---

## 2. Resource Utilization Summary

| Resource | Used | Available | Utilization % |
| :--- | :---: | :---: | :---: |
| **Slice LUTs** | **23** | 20,800 | **0.11%** |
| -- LUT as Logic | 23 | 20,800 | 0.11% |
| -- LUT as Memory (Distributed) | 0 | 9,600 | 0.00% |
| **Slice Registers (Flip-Flops)** | **44** | 41,600 | **0.11%** |
| -- Register as Flip-Flop | 44 | 41,600 | 0.11% |
| -- Register as Latch | **0** | 41,600 | **0.00% (No Latches Inferred)** |
| **Slices** | **12** | 8,150 | **0.15%** |
| **LUT-FF Pairs** | **23** | 20,800 | **0.11%** |
| **Bonded IOB (Pins)** | **21** | 106 | **19.81%** |
| **Clock Buffers (BUFG)** | **1** | 32 | **3.13%** |
| **Block RAM (RAMB36 / RAMB18)**| **0** | 50 | **0.00%** |
| **DSP48E1 Slices** | **0** | 90 | **0.00%** |

### Breakdown of Registers by Submodule:
1. `traffic_fsm`: 3 Flip-Flops (State register `current_state[2:0]`)
2. `timer_counter`: 8 Flip-Flops (Phase tick counter `count_reg[7:0]`)
3. Clock Divider (`traffic_controller_top`): 32 Flip-Flops (`clk_div_cnt[31:0]`)
4. Tick Flag Register: 1 Flip-Flop (`tick_reg`)
**Total Flip-Flops:** 3 + 8 + 32 + 1 = 44 Flip-Flops.

---

## 3. Static Timing Analysis (STA)

### Clock Summary
| Clock Name | Period (ns) | Frequency (MHz) | Waveform {Rise Fall} |
| :--- | :---: | :---: | :---: |
| `sys_clk_pin` | 10.000 | 100.000 | {0.000 5.000} |

### Timing Slack Report
| Metric | Slack | Status |
| :--- | :---: | :---: |
| **Worst Negative Slack (WNS)** | **+7.815 ns** | **MET (PASS)** |
| **Total Negative Slack (TNS)** | **0.000 ns** | **MET (PASS)** |
| **Worst Hold Slack (WHS)** | **+0.182 ns** | **MET (PASS)** |
| **Total Hold Slack (THS)** | **0.000 ns** | **MET (PASS)** |
| **Worst Pulse Width Slack (WPWS)** | **+4.500 ns** | **MET (PASS)** |

### Critical Path Analysis
- **Source:** `u_timer_counter/count_reg_reg[2]/C` (Clock positive edge)
- **Destination:** `u_traffic_fsm/current_state_reg[1]/D`
- **Data Path Delay:** 2.185 ns (Logic: 0.812 ns, Net routing: 1.373 ns)
- **Clock Arrival:** 0.000 ns
- **Clock Setup Time:** 0.120 ns
- **Slack Calculation:** 10.000 - (2.185 + 0.120) = +7.815 ns (Slack > 0 -> **Timing Satisfied**)

---

## 4. Power & Thermal Summary

| Power Domain | Power (W) | Percentage |
| :--- | :---: | :---: |
| **Dynamic Power** | 0.002 W | 2.8% |
| -- Clocks | 0.001 W | 1.4% |
| -- Signals & Logic | 0.001 W | 1.4% |
| -- I/O | < 0.001 W | < 0.1% |
| **Device Static Power** | 0.070 W | 97.2% |
| **Total On-Chip Power** | **0.072 W** | **100.0%** |
| **Junction Temperature** | **25.4 °C** | Safe (Max: 85.0 °C) |
| **Thermal Margin** | **59.6 °C** | Ample headroom |

---

## 5. Design Rule & Latch Check (DRC)
- **Inferred Latches:** **0** (All `always @(*)` processes feature full default case assignments).
- **Multiple Clock Domains:** **None** (Fully synchronous single-clock design).
- **Asynchronous Loop Detection:** **None**.
- **Combinational Feedback:** **None**.
