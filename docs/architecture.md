# Four-Way Traffic Light Controller - Architecture Specification

## 1. System Overview

The **Four-Way Traffic Light Controller** is a high-reliability, synthesizable digital RTL core designed in Verilog HDL. It manages vehicular traffic flow at a four-way intersection (**North, South, East, West**) using an 8-state Moore Finite State Machine (FSM), a parameterized synchronous timer counter, a combinational output decoder, and an integrated FPGA clock divider.

The primary safety requirement of the system is **zero conflicting green lights**: at any given moment, exactly one direction is granted a green light, while all orthogonal/conflicting directions are held strictly red.

---

## 2. Top-Level Microarchitecture

```
                                  +-----------------------------------------------------------+
                                  |                 traffic_controller_top                    |
                                  |                                                           |
          clk (100MHz) ---------->|   +-----------------------+                               |
          rst (Sync Active-High)->|   | Clock Divider / Tick  |                               |
                                  |   | (50M / 1Hz / Sim-Mode)|                               |
                                  |   +-----------+-----------+                               |
                                  |               | tick_enable                               |
                                  |               v                                           |
                                  |   +-----------------------+                               |
                                  |   |     timer_counter     |<-------+                      |
                                  |   | (Counts Phase Ticks)  |        | timer_clear          |
                                  |   +-----------+-----------+        | duration_sel         |
                                  |               | timer_done         |                      |
                                  |               v                    |                      |
                                  |   +-----------------------+--------+                      |
                                  |   |      traffic_fsm      |                               |
                                  |   |   (8-State Moore)     |                               |
                                  |   +-----------+-----------+                               |
                                  |               |                                           |
                                  |               | current_state[2:0]                        |
                                  |               v                                           |
                                  |   +-----------------------+                               |
                                  |   |    signal_decoder     |                               |
                                  |   +-----------+-----------+                               |
                                  |               |                                           |
                                  +---------------|-------------------------------------------+
                                                  |
           +-------------------------+------------+------------+-------------------------+
           |                         |                         |                         |
           v                         v                         v                         v
     North Signals             South Signals              East Signals              West Signals
    {R, Y, G} / 3-bit         {R, Y, G} / 3-bit         {R, Y, G} / 3-bit         {R, Y, G} / 3-bit
```

---

## 3. Submodule Specifications

### 3.1. Clock Divider & Tick Generator (`traffic_controller_top`)
- In hardware FPGA deployment (`SIMULATION_MODE = 0`), the 100 MHz board oscillator is scaled down to a 1-cycle `tick_enable` strobe asserted once per second (1 Hz).
- In simulation mode (`SIMULATION_MODE = 1`), `tick_enable` is continuously tied to logic `1'b1`, enabling test scenarios to complete in nanoseconds rather than wall-clock seconds.

### 3.2. Synchronous Timer Counter (`timer_counter.v`)
- **Parameters:** `WIDTH` (default 8 bits, counts up to 255 ticks).
- **Interface:**
  - `clk`, `rst`: Synchronous clock and active-high reset.
  - `timer_enable`: Advances counter on posedge `clk` when active.
  - `timer_clear`: Synchronously re-arms the counter to 0 upon state transition.
  - `target_ticks[WIDTH-1:0]`: Target threshold (`GREEN_TICKS` or `YELLOW_TICKS`).
  - `timer_done`: Combinational indicator asserted on the final cycle (`count_reg >= target_ticks - 1`).
  - `count_out[WIDTH-1:0]`: Internal count register value.

### 3.3. 8-State Moore FSM (`traffic_fsm.v`)
- Implements the sequential round-robin traffic progression across North -> South -> East -> West.
- Utilizes the industry-standard **3-process FSM coding architecture**:
  1. Synchronous state register with synchronous active-high reset.
  2. Combinational next-state decode based on `timer_done`.
  3. Output generation for `duration_sel` and `timer_clear`.

### 3.4. Signal Decoder (`signal_decoder.v`)
- Purely combinational logic mapping the 3-bit FSM state to 12 physical lamp signals.
- Guarantees fail-safe behavior: any illegal or unmapped state immediately forces all directions to **RED** (`3'b100`).

---

## 4. Interface Port Definitions

| Signal Name | Direction | Width | Description |
| :--- | :---: | :---: | :--- |
| `clk` | Input | 1 | Master system clock (100 MHz on Digilent Basys 3 / Nexys A7). |
| `rst` | Input | 1 | Synchronous active-high system reset. |
| `north_red` | Output | 1 | North direction Red stop lamp. |
| `north_yellow`| Output | 1 | North direction Yellow warning lamp. |
| `north_green` | Output | 1 | North direction Green go lamp. |
| `north_lights`| Output | 3 | Bundled North light bus: `{Red, Yellow, Green}`. |
| `south_red` | Output | 1 | South direction Red stop lamp. |
| `south_yellow`| Output | 1 | South direction Yellow warning lamp. |
| `south_green` | Output | 1 | South direction Green go lamp. |
| `south_lights`| Output | 3 | Bundled South light bus: `{Red, Yellow, Green}`. |
| `east_red` | Output | 1 | East direction Red stop lamp. |
| `east_yellow` | Output | 1 | East direction Yellow warning lamp. |
| `east_green` | Output | 1 | East direction Green go lamp. |
| `east_lights` | Output | 3 | Bundled East light bus: `{Red, Yellow, Green}`. |
| `west_red` | Output | 1 | West direction Red stop lamp. |
| `west_yellow` | Output | 1 | West direction Yellow warning lamp. |
| `west_green` | Output | 1 | West direction Green go lamp. |
| `west_lights` | Output | 3 | Bundled West light bus: `{Red, Yellow, Green}`. |
| `state_out` | Output | 3 | Current FSM state (`3'b000` to `3'b111`) for onboard diagnostic LEDs. |
| `time_remaining`| Output | 8 | Remaining tick countdown for seven-segment display or logic analysis. |

---

## 5. Light Bus Encodings
Each 3-bit light bus follows the format `{Red, Yellow, Green}`:
- `3'b100`: **RED** (Active Stop)
- `3'b010`: **YELLOW** (Active Transition / Caution)
- `3'b001`: **GREEN** (Active Go)
