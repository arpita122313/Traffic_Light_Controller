# VLSI RTL Design & Placement Preparation - 25 Technical Interview Questions & Answers

This document provides 25 in-depth technical interview questions and comprehensive model answers based on the **Four-Way Traffic Light Controller** project. Tailored specifically for core VLSI, FPGA, and ASIC hardware design job interviews (e.g. Intel, AMD, NVIDIA, Qualcomm, Texas Instruments, Synopsys, Cadence).

---

### Q1. Why did you choose a Moore FSM over a Mealy FSM for this Traffic Light Controller?
**Answer:**  
In a **Moore FSM**, the outputs depend solely on the current registered state (`Output = f(State)`), whereas in a **Mealy FSM**, outputs depend on both the current state and asynchronous primary inputs (`Output = f(State, Inputs)`).  
For safety-critical hardware like a traffic light controller:
1. **Glitch Immunity:** In a Mealy machine, any combinational glitch or hazard on an input signal directly propagates to the output lamps. In a Moore machine, output transitions only occur on active clock edges.
2. **Predictable Timing:** Moore outputs remain stable throughout the entire clock period, greatly simplifying downstream setup and hold timing closure.

---

### Q2. How did you ensure that two conflicting directions never turn green simultaneously?
**Answer:**  
Mutual exclusion was enforced at both the architectural design level and the verification level:
1. **State Isolation:** The FSM defines 8 disjoint states. In each state, exactly one direction is assigned to Green or Yellow, while all remaining three directions are explicitly driven with Red (`LIGHT_RED = 3'b100`).
2. **Fail-Safe Default Case:** In `signal_decoder.v`, the `default` branch assigns all four directions to Red (`3'b100`).
3. **Continuous Testbench Assertions:** A concurrent checker checks every clock cycle that:
   $$\text{north\_green} + \text{south\_green} + \text{east\_green} + \text{west\_green} \le 1$$
   If this sum exceeds 1, simulation terminates immediately with a fatal error.

---

### Q3. Why is a synchronous active-high reset preferred in modern Xilinx 7-Series FPGAs?
**Answer:**  
1. **Dedicated Flip-Flop Control Pins:** In Xilinx 7-Series (Artix-7/Kintex-7/Virtex-7) Slice flip-flops, the dedicated control pin is an active-high synchronous reset/clear (`SR` pin).
2. **Resource Optimization:** Using an asynchronous reset or active-low reset forces synthesis to either insert LUT inverters or use suboptimal routing resources.
3. **Predictable Reset Recovery:** Synchronous resets are completely synchronous to `clk`, eliminating reset removal recovery/removal timing violations that occur with asynchronous reset deassertion.

---

### Q4. Explain the difference between 1-always, 2-always, and 3-always block FSM coding styles. Which did you use?
**Answer:**  
- **1-Always Block:** Combines state registers, next-state logic, and output decoding in a single clocked `always @(posedge clk)` block. This registers all outputs, but makes next-state combinational logic harder to modify and debug.
- **2-Always Block:** Separates sequential state register update (`always @(posedge clk)`) from combinational next-state and output decoding (`always @(*)`).
- **3-Always Block (Industry Best Practice - Used Here):**
  - Block 1 (`always @(posedge clk)`): Synchronous state register update.
  - Block 2 (`always @(*)`): Combinational next-state evaluation.
  - Block 3 (`always @(*)` or continuous assigns): Combinational output generation (or registered output stage).  
  This provides the cleanest separation of concerns, simplifies static timing analysis, and completely prevents unintended latch inference.

---

### Q5. How does the timer counter avoid an off-by-one cycle error during phase transitions?
**Answer:**  
When counting from 0 up to $N$ clock cycles:
- Cycle 0: `count_reg = 0`
- Cycle 1: `count_reg = 1`
- ...
- Cycle $N-1$: `count_reg = N - 1`. At this cycle, `count_reg >= target_ticks - 1`, asserting `timer_done = 1`.
- On the next active clock edge ($N$-th clock edge):
  - The FSM registers the new state (`next_state`).
  - The counter registers `count_reg <= 0` (via `timer_clear` or auto-clear).
- Thus, the controller spends exactly $N$ clock cycles in each phase with zero lost or extra cycles.

---

### Q6. What is the difference between Binary, Gray, and One-Hot state encodings? Which is optimal for FPGAs?
**Answer:**  
- **Binary:** Uses $\lceil \log_2 N \rceil$ registers. Dense, low flip-flop utilization, but multiple bits can toggle simultaneously, increasing dynamic switching power.
- **Gray:** Adjacent states differ by exactly 1 bit. Minimizes switching power and eliminates intermediate glitch transitions.
- **One-Hot:** Uses $N$ registers for $N$ states (1 register per state). Since FPGAs have abundant flip-flops and 4-to-6 input LUT architectures, One-Hot minimizes combinational decoding depth, leading to the highest clock frequency ($F_{\max}$) for large FSMs (>16 states). For small 8-state FSMs, Binary or Gray encoding is compact and efficient.

---

### Q7. What happens if an illegal state occurs due to an SEU (Single Event Upset / Alpha particle)?
**Answer:**  
In our design, the 3-bit binary encoding has $2^3 = 8$ total combinations, and all 8 combinations are fully utilized (`3'b000` to `3'b111`). If an upset occurs, the FSM transitions to another valid state rather than hanging. Furthermore, the `default:` clause in both `traffic_fsm.v` and `signal_decoder.v` explicitly defaults to `S_NORTH_GREEN` and forces all signals to **RED**, guaranteeing fail-safe recovery.

---

### Q8. What is the difference between blocking (`=`) and non-blocking (`<=`) assignments? Where did you use each?
**Answer:**  
- **Non-Blocking (`<=`):** Evaluates the RHS on posedge and updates the LHS at the end of the time step. Used in **all sequential `always @(posedge clk)` blocks** to avoid race conditions and model parallel hardware registers.
- **Blocking (`=`):** Executes sequentially like software. Used in **all combinational `always @(*)` blocks** to ensure immediate evaluation of intermediate variables without latch inference.

---

### Q9. How did you ensure your design never infers unintended latches during synthesis?
**Answer:**  
A latch is inferred by synthesis when a combinational signal in an `always @(*)` block is not assigned a value in all possible evaluation paths (e.g., missing `else` or missing `default` in a `case` statement).  
To prevent latches:
1. Every `case` statement includes a comprehensive `default` clause.
2. Default output assignments (`n_reg = LIGHT_RED; ...`) are placed at the very top of each combinational process before entering the `case` statement.

---

### Q10. Why is using a clock enable (`tick_enable`) superior to generating a divided clock (`clk_1hz`) for flip-flops?
**Answer:**  
Generating a new clock signal via logic (e.g. `always @(posedge clk) clk_1hz <= ~clk_1hz;`) creates a **gated/ripple clock**. This introduces:
1. Significant clock skew relative to the master clock.
2. Additional Clock Domain Crossing (CDC) boundaries.
3. Wasted Global Clock Buffer (BUFG) resources.  
By instead keeping all registers on the master 100 MHz clock and asserting a 1-cycle **clock enable pulse** (`tick_enable`), all flip-flops remain completely synchronous, share the low-skew master clock tree, and timing analysis is single-domain and deterministic.

---

### Q11. Define Setup Time ($T_{su}$) and Hold Time ($T_h$). What is Slack?
**Answer:**  
- **Setup Time ($T_{su}$):** The minimum time data must remain stable *before* the active clock edge.
- **Hold Time ($T_h$):** The minimum time data must remain stable *after* the active clock edge.
- **Setup Slack:** $T_{clk} - (T_{cq} + T_{comb} + T_{su})$. Positive slack indicates timing is satisfied.
- In our synthesis report, Worst Negative Slack (**WNS**) is **+7.815 ns** against a 10.000 ns clock, meaning setup timing is met with a 78% safety margin.

---

### Q12. What is Clock Jitter and Clock Skew?
**Answer:**  
- **Clock Skew:** Spatial difference in clock arrival times at different flip-flop clock pins due to physical routing wire length differences.
- **Clock Jitter:** Temporal variations in the clock period from cycle to cycle caused by oscillator noise, power supply ripple, or PLL phase error.

---

### Q13. How did your design achieve 0.000 ns Total Negative Slack (TNS)?
**Answer:**  
TNS is the sum of all negative slacks across all failing endpoints. A TNS of 0.000 ns indicates that every single timing path in the design satisfies setup and hold requirements without a single timing violation.

---

### Q14. What are the key sections of a Synopsys Design Constraints (SDC / XDC) file?
**Answer:**  
1. **Clock Constraints:** Defining primary clocks (`create_clock -period 10.000 ...`).
2. **I/O Delays:** `set_input_delay` and `set_output_delay`.
3. **Physical Pin & Voltage Constraints:** `set_property PACKAGE_PIN ...` and `set_property IOSTANDARD LVCMOS33 ...`.
4. **Timing Exceptions:** `set_false_path`, `set_multicycle_path` (if applicable).

---

### Q15. How would you handle Clock Domain Crossing (CDC) if pedestrian pushbuttons were added?
**Answer:**  
Pushbuttons are asynchronous inputs driven by humans. To safely sample an asynchronous input without metastability:
1. Pass the signal through a **2-Flip-Flop Synchronizer** (two back-to-back registers clocked by the system clock).
2. Follow with a digital debouncing filter to eliminate mechanical contact bounces before feeding the signal into the FSM.

---

### Q16. What is Metastability and how does a 2-FF synchronizer mitigate it?
**Answer:**  
When an asynchronous input transitions within the setup/hold window of a flip-flop, the flip-flop output may oscillate or hover at an intermediate voltage level for an indeterminate time.  
A 2-FF synchronizer allows the first flip-flop an entire clock cycle to resolve its metastable state to a valid logic level before the second flip-flop samples it, exponentially reducing the Mean Time Between Failures (MTBF).

---

### Q17. How does parameterization benefit this RTL design?
**Answer:**  
Parameters (`TIMER_WIDTH`, `GREEN_TICKS`, `YELLOW_TICKS`, `CLK_DIV_MAX`, `SIMULATION_MODE`) allow the module to be instantly reconfigured without modifying RTL code. For example, during verification, `SIMULATION_MODE=1` speeds up testing by 50,000,000x, while `SIMULATION_MODE=0` deploys to hardware with real-time 1-second intervals.

---

### Q18. Explain the difference between Functional (Behavioral) Simulation and Post-Synthesis / Post-Layout Timing Simulation.
**Answer:**  
- **Behavioral Simulation:** Simulates purely ideal RTL logic with zero gate and net wire delays. Fast and used for algorithm/functional verification.
- **Timing Simulation:** Back-annotates real gate delays and interconnect routing delays from the synthesized netlist via a Standard Delay Format (SDF) file, verifying that setup and hold times are satisfied under worst-case PVT (Process, Voltage, Temperature) conditions.

---

### Q19. What is the role of a Global Clock Buffer (BUFG) in Xilinx FPGAs?
**Answer:**  
A BUFG is a specialized high-drive buffer that distributes a clock signal across dedicated low-skew clock distribution networks spanning the entire FPGA die. In our synthesis report, 1 BUFG is utilized for the 100 MHz `clk` input pin.

---

### Q20. How did you structure your testbench for automated self-checking?
**Answer:**  
The testbench does not rely on visual inspection of waveforms:
1. It maintains automated pass/fail counters (`tests_passed`, `tests_failed`).
2. It uses parameterized verification tasks (`assert_phase`, `wait_and_verify_duration`) that automatically check output vectors against expected golden values.
3. Concurrent continuous assertions flag any safety violations immediately.
4. Generates an IEEE 1364 standard VCD waveform file and prints a comprehensive execution summary table.

---

### Q21. What is the function of `$dumpfile` and `$dumpvars` in Verilog?
**Answer:**  
- `$dumpfile("filename.vcd")`: Specifies the output VCD (Value Change Dump) file to record signal transitions.
- `$dumpvars(level, module)`: Tells the simulator which hierarchy levels and nets to log (`level 0` logs all signals in the specified testbench hierarchy).

---

### Q22. Explain Static Power vs Dynamic Power in CMOS/FPGA devices.
**Answer:**  
- **Dynamic Power:** Power consumed when transistors switch states, caused by charging/discharging parasitic load capacitances and short-circuit current: $P_{dyn} = \alpha \cdot C \cdot V^2 \cdot f$.
- **Static Power:** Power consumed when the device is idle, caused by subthreshold leakage, gate oxide leakage, and reverse junction bias current: $P_{stat} = I_{leak} \cdot V$.
- In our synthesis report, total on-chip power is **0.072 W** (Dynamic: 0.002 W, Static: 0.070 W).

---

### Q23. What are Look-Up Tables (LUTs) in Xilinx 7-Series FPGAs?
**Answer:**  
In 7-series FPGAs, a Look-Up Table (LUT6) is a 6-input SRAM-based truth table capable of implementing any arbitrary 6-input Boolean function, or two 5-input functions with shared inputs. Our design synthesized into **23 Slice LUTs**, representing only 0.11% of the FPGA.

---

### Q24. How do you verify continuous multi-cycle stability in an FSM?
**Answer:**  
By running continuous stress tests across multiple complete round-robin cycles (TC-13 ran for over 312 clock cycles covering 3+ complete cycles). This verifies that internal counters reset deterministically on each pass, no phase shifts occur, and no arithmetic overflow leaks into subsequent cycles.

---

### Q25. What is the significance of the `timescale 1ns / 1ps compiler directive?
**Answer:**  
- `1ns`: The **time unit** (e.g. `#10` represents 10 ns delay).
- `1ps`: The **time precision** (simulator calculates events rounded to the nearest 1 picosecond).
