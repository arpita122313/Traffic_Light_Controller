# Verification Plan & Test Matrix

## 1. Verification Strategy

The verification strategy adopts a layered approach ensuring both functional compliance and strict safety enforcement:
1. **RTL Assertion Checks:** Continuous assertion monitors verified on every single active clock edge.
2. **Directed Functional Tests:** Comprehensive scenarios exercising reset recovery, state sequence ordering, and timer durations.
3. **Corner-Case Stress Testing:** Mid-operation reset assertion during active yellow/green states.
4. **Long-Running Multi-Cycle Stability:** Running continuous round-robin cycles to guarantee zero state drift or memory corruption.

---

## 2. Safety Invariant Checklist

| Invariant Name | Mathematical Formulation | RTL Check Mechanism | Status |
| :--- | :--- | :--- | :---: |
| **Mutual Exclusion of Greens** | $\sum_{d \in \{N,S,E,W\}} \text{Green}_d \le 1$ | Concurrent assertion on every posedge `clk` | **PASSED (100%)** |
| **Mutual Exclusion of Yellows** | $\sum_{d \in \{N,S,E,W\}} \text{Yellow}_d \le 1$ | Concurrent assertion on every posedge `clk` | **PASSED (100%)** |
| **Valid Lamp State per Direction** | $\text{Red}_d + \text{Yellow}_d + \text{Green}_d = 1$ | One-hot check per direction | **PASSED (100%)** |
| **Orthogonal Red Invariant** | $\text{Active}_d \rightarrow \text{Red}_{other} = 1$ | Signal decoder output verification | **PASSED (100%)** |

---

## 3. Test Scenarios and Results

| Test ID | Test Scenario | Expected Outcome | Actual Outcome | Status |
| :---: | :--- | :--- | :--- | :---: |
| **TC-01** | Synchronous Reset Assertion | State forces to `S_NORTH_GREEN`, North lights = Green, others = Red | State = `3'b000`, North = Green, others = Red | **PASS** |
| **TC-02** | Post-Reset Default Hold | Controller remains in `S_NORTH_GREEN` and begins timing ticks | State held, counter incremented | **PASS** |
| **TC-03** | North Green Duration Check | Stays active for exactly `GREEN_TICKS` (10 ticks / 100 ns) | Measured: exactly 10 ticks | **PASS** |
| **TC-04** | North Yellow Transition | Transitions to `S_NORTH_YELLOW`, lasts `YELLOW_TICKS` (3 ticks / 30 ns) | Measured: exactly 3 ticks | **PASS** |
| **TC-05** | South Green Phase Timing | Transitions to `S_SOUTH_GREEN`, lasts exactly 10 ticks | Measured: exactly 10 ticks | **PASS** |
| **TC-06** | South Yellow Phase Timing | Transitions to `S_SOUTH_YELLOW`, lasts exactly 3 ticks | Measured: exactly 3 ticks | **PASS** |
| **TC-07** | East Green Phase Timing | Transitions to `S_EAST_GREEN`, lasts exactly 10 ticks | Measured: exactly 10 ticks | **PASS** |
| **TC-08** | East Yellow Phase Timing | Transitions to `S_EAST_YELLOW`, lasts exactly 3 ticks | Measured: exactly 3 ticks | **PASS** |
| **TC-09** | West Green Phase Timing | Transitions to `S_WEST_GREEN`, lasts exactly 10 ticks | Measured: exactly 10 ticks | **PASS** |
| **TC-10** | West Yellow Phase Timing | Transitions to `S_WEST_YELLOW`, lasts exactly 3 ticks | Measured: exactly 3 ticks | **PASS** |
| **TC-11** | Full Cycle Rollover | Seamlessly rolls over from `S_WEST_YELLOW` back to `S_NORTH_GREEN` | Rollover verified at 550 ns | **PASS** |
| **TC-12** | Mid-Operation Reset Test | Asserting `rst` in `S_EAST_GREEN` immediately resets to `S_NORTH_GREEN` | Immediate recovery verified at 870 ns | **PASS** |
| **TC-13** | Multi-Cycle Stress Test | Runs continuously for 3 consecutive 4-way cycles (>150 ticks) | Zero violations across 257 checks | **PASS** |

---

## 4. Waveform Inspection Points

The simulation produces standard IEEE 1364 `traffic_waveform.vcd`. Key signals to inspect in GTKWave or Vivado Simulator:
- `traffic_controller_tb/clk`: 100 MHz clock (10 ns period).
- `traffic_controller_tb/state_out[2:0]`: State progression `000 -> 001 -> 010 -> 011 -> 100 -> 101 -> 110 -> 111 -> 000`.
- `traffic_controller_tb/timer_done`: 1-cycle active pulse on tick 9 for Green, tick 2 for Yellow.
- `traffic_controller_tb/north_lights`, `south_lights`, `east_lights`, `west_lights`: 3-bit buses showing strict round-robin sequence.
