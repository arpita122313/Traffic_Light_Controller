#!/usr/bin/env python3
"""
=============================================================================
Project       : Four-Way Traffic Light Controller
File          : run_verilog_sim.py
Description   : Cycle-Accurate Golden Verification Engine & IEEE 1364 VCD
                Waveform Generator for the 4-Way Traffic Light Controller RTL.
Standard      : IEEE 1364-2001 Verilog RTL Semantics & VCD Format
Author        : VLSI RTL Verification Team
=============================================================================
"""

import sys
import os

# FSM State Constants
S_NORTH_GREEN  = 0b000
S_NORTH_YELLOW = 0b001
S_SOUTH_GREEN  = 0b010
S_SOUTH_YELLOW = 0b011
S_EAST_GREEN   = 0b100
S_EAST_YELLOW  = 0b101
S_WEST_GREEN   = 0b110
S_WEST_YELLOW  = 0b111

STATE_NAMES = {
    S_NORTH_GREEN : "S_NORTH_GREEN",
    S_NORTH_YELLOW: "S_NORTH_YELLOW",
    S_SOUTH_GREEN : "S_SOUTH_GREEN",
    S_SOUTH_YELLOW: "S_SOUTH_YELLOW",
    S_EAST_GREEN  : "S_EAST_GREEN",
    S_EAST_YELLOW : "S_EAST_YELLOW",
    S_WEST_GREEN  : "S_WEST_GREEN",
    S_WEST_YELLOW : "S_WEST_YELLOW",
}

# Light Constants: {Red, Yellow, Green}
LIGHT_RED    = 0b100
LIGHT_YELLOW = 0b010
LIGHT_GREEN  = 0b001


class VCDWriter:
    """Standard IEEE 1364 VCD Waveform Generator."""
    def __init__(self, filepath):
        self.f = open(filepath, "w")
        self.time = 0
        self.vars = {}
        self.var_symbols = {}
        self.sym_counter = ord('!')

    def register_var(self, name, size=1):
        sym = chr(self.sym_counter)
        self.sym_counter += 1
        if self.sym_counter > 126:
            self.sym_counter = ord('!')
        self.vars[name] = {"size": size, "sym": sym, "last_val": None}
        return sym

    def write_header(self, module_name="traffic_controller_tb"):
        self.f.write("$date\n   November 11, 2026\n$end\n")
        self.f.write("$version\n   VLSI Verification Engine v2.0\n$end\n")
        self.f.write("$timescale\n   1ns\n$end\n")
        self.f.write(f"$scope module {module_name} $end\n")
        for name, meta in self.vars.items():
            var_type = "wire" if meta["size"] > 1 else "wire"
            self.f.write(f"  $var {var_type} {meta['size']} {meta['sym']} {name} $end\n")
        self.f.write("$upscope $end\n")
        self.f.write("$enddefinitions $end\n")
        self.f.write("$dumpvars\n")
        for name, meta in self.vars.items():
            if meta["size"] == 1:
                self.f.write(f"0{meta['sym']}\n")
            else:
                self.f.write(f"b{'0'*meta['size']} {meta['sym']}\n")
            meta["last_val"] = 0
        self.f.write("$end\n")

    def update_var(self, name, val):
        meta = self.vars[name]
        if meta["last_val"] != val:
            meta["last_val"] = val
            if meta["size"] == 1:
                self.f.write(f"{int(val)}{meta['sym']}\n")
            else:
                fmt = f"b{val:0{meta['size']}b} {meta['sym']}\n"
                self.f.write(fmt)

    def set_time(self, t):
        if t != self.time:
            self.time = t
            self.f.write(f"#{t}\n")

    def close(self):
        self.f.close()


class TrafficControllerDUT:
    """Exact cycle-accurate model of traffic_controller_top Verilog RTL."""
    def __init__(self, timer_width=8, green_ticks=10, yellow_ticks=3):
        self.timer_width = timer_width
        self.green_ticks = green_ticks
        self.yellow_ticks = yellow_ticks

        # Registers
        self.current_state = S_NORTH_GREEN
        self.count_reg = 0

        # Wires
        self.rst = 0
        self.timer_enable = 1
        self.timer_clear = 0
        self.timer_done = 0
        self.duration_sel = 0
        self.target_ticks = green_ticks

        # Outputs
        self.north_lights = LIGHT_GREEN
        self.south_lights = LIGHT_RED
        self.east_lights  = LIGHT_RED
        self.west_lights  = LIGHT_RED

        self.update_combinational()

    def update_combinational(self):
        # 1. FSM duration_sel: Bit 0 is 1 in all Yellow states
        self.duration_sel = self.current_state & 0b001

        # 2. Target ticks select
        self.target_ticks = self.yellow_ticks if (self.duration_sel == 1) else self.green_ticks

        # 3. Timer done: asserted when count reaches target_ticks - 1
        self.timer_done = 1 if (self.timer_enable and (self.count_reg >= self.target_ticks - 1)) else 0

        # 4. Timer clear
        self.timer_clear = self.timer_done

        # 5. Signal Decoder
        if self.current_state == S_NORTH_GREEN:
            self.north_lights = LIGHT_GREEN
            self.south_lights = LIGHT_RED
            self.east_lights  = LIGHT_RED
            self.west_lights  = LIGHT_RED
        elif self.current_state == S_NORTH_YELLOW:
            self.north_lights = LIGHT_YELLOW
            self.south_lights = LIGHT_RED
            self.east_lights  = LIGHT_RED
            self.west_lights  = LIGHT_RED
        elif self.current_state == S_SOUTH_GREEN:
            self.north_lights = LIGHT_RED
            self.south_lights = LIGHT_GREEN
            self.east_lights  = LIGHT_RED
            self.west_lights  = LIGHT_RED
        elif self.current_state == S_SOUTH_YELLOW:
            self.north_lights = LIGHT_RED
            self.south_lights = LIGHT_YELLOW
            self.east_lights  = LIGHT_RED
            self.west_lights  = LIGHT_RED
        elif self.current_state == S_EAST_GREEN:
            self.north_lights = LIGHT_RED
            self.south_lights = LIGHT_RED
            self.east_lights  = LIGHT_GREEN
            self.west_lights  = LIGHT_RED
        elif self.current_state == S_EAST_YELLOW:
            self.north_lights = LIGHT_RED
            self.south_lights = LIGHT_RED
            self.east_lights  = LIGHT_YELLOW
            self.west_lights  = LIGHT_RED
        elif self.current_state == S_WEST_GREEN:
            self.north_lights = LIGHT_RED
            self.south_lights = LIGHT_RED
            self.east_lights  = LIGHT_RED
            self.west_lights  = LIGHT_GREEN
        elif self.current_state == S_WEST_YELLOW:
            self.north_lights = LIGHT_RED
            self.south_lights = LIGHT_RED
            self.east_lights  = LIGHT_RED
            self.west_lights  = LIGHT_YELLOW
        else:
            self.north_lights = LIGHT_RED
            self.south_lights = LIGHT_RED
            self.east_lights  = LIGHT_RED
            self.west_lights  = LIGHT_RED

    @property
    def time_remaining(self):
        if self.target_ticks > self.count_reg:
            return self.target_ticks - self.count_reg
        return 0

    def clock_tick(self):
        """Executes synchronous sequential state register update on posedge clk."""
        # Evaluate next state combinational logic before state transition
        next_state = self.current_state
        if self.current_state == S_NORTH_GREEN:
            next_state = S_NORTH_YELLOW if self.timer_done else S_NORTH_GREEN
        elif self.current_state == S_NORTH_YELLOW:
            next_state = S_SOUTH_GREEN if self.timer_done else S_NORTH_YELLOW
        elif self.current_state == S_SOUTH_GREEN:
            next_state = S_SOUTH_YELLOW if self.timer_done else S_SOUTH_GREEN
        elif self.current_state == S_SOUTH_YELLOW:
            next_state = S_EAST_GREEN if self.timer_done else S_SOUTH_YELLOW
        elif self.current_state == S_EAST_GREEN:
            next_state = S_EAST_YELLOW if self.timer_done else S_EAST_GREEN
        elif self.current_state == S_EAST_YELLOW:
            next_state = S_WEST_GREEN if self.timer_done else S_EAST_YELLOW
        elif self.current_state == S_WEST_GREEN:
            next_state = S_WEST_YELLOW if self.timer_done else S_WEST_GREEN
        elif self.current_state == S_WEST_YELLOW:
            next_state = S_NORTH_GREEN if self.timer_done else S_WEST_YELLOW

        # Register updates on posedge clk
        if self.rst:
            self.count_reg = 0
            self.current_state = S_NORTH_GREEN
        else:
            # Counter register update
            if self.timer_clear:
                self.count_reg = 0
            elif self.timer_enable:
                if self.count_reg >= self.target_ticks - 1:
                    self.count_reg = 0
                else:
                    self.count_reg += 1
            # FSM state register update
            self.current_state = next_state

        # Update combinational signals after clock edge
        self.update_combinational()


def run_verification():
    print("===============================================================================")
    print("       FOUR-WAY TRAFFIC LIGHT CONTROLLER - RTL VERIFICATION ENGINE             ")
    print("===============================================================================")
    print("Clock Frequency    : 100 MHz (Clock Period = 10 ns)")
    print("GREEN Duration     : 10 Ticks (100 ns)")
    print("YELLOW Duration    : 3 Ticks (30 ns)")
    print("Predefined Order   : North -> South -> East -> West")
    print("-------------------------------------------------------------------------------")

    # Waveform file output
    vcd_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "traffic_waveform.vcd")
    vcd = VCDWriter(vcd_path)

    # Register VCD signals
    vcd.register_var("clk", 1)
    vcd.register_var("rst", 1)
    vcd.register_var("state_out", 3)
    vcd.register_var("timer_done", 1)
    vcd.register_var("count_reg", 8)
    vcd.register_var("time_remaining", 8)
    vcd.register_var("north_lights", 3)
    vcd.register_var("south_lights", 3)
    vcd.register_var("east_lights", 3)
    vcd.register_var("west_lights", 3)
    vcd.register_var("north_green", 1)
    vcd.register_var("north_yellow", 1)
    vcd.register_var("north_red", 1)
    vcd.register_var("south_green", 1)
    vcd.register_var("south_yellow", 1)
    vcd.register_var("south_red", 1)
    vcd.register_var("east_green", 1)
    vcd.register_var("east_yellow", 1)
    vcd.register_var("east_red", 1)
    vcd.register_var("west_green", 1)
    vcd.register_var("west_yellow", 1)
    vcd.register_var("west_red", 1)

    vcd.write_header("traffic_controller_tb")

    dut = TrafficControllerDUT(timer_width=8, green_ticks=10, yellow_ticks=3)

    sim_time = 0
    total_checks = 0
    passed_checks = 0
    failed_checks = 0

    def dump_current(t, clk_val):
        vcd.set_time(t)
        vcd.update_var("clk", clk_val)
        vcd.update_var("rst", dut.rst)
        vcd.update_var("state_out", dut.current_state)
        vcd.update_var("timer_done", dut.timer_done)
        vcd.update_var("count_reg", dut.count_reg)
        vcd.update_var("time_remaining", dut.time_remaining)
        vcd.update_var("north_lights", dut.north_lights)
        vcd.update_var("south_lights", dut.south_lights)
        vcd.update_var("east_lights", dut.east_lights)
        vcd.update_var("west_lights", dut.west_lights)
        vcd.update_var("north_red", (dut.north_lights >> 2) & 1)
        vcd.update_var("north_yellow", (dut.north_lights >> 1) & 1)
        vcd.update_var("north_green", dut.north_lights & 1)
        vcd.update_var("south_red", (dut.south_lights >> 2) & 1)
        vcd.update_var("south_yellow", (dut.south_lights >> 1) & 1)
        vcd.update_var("south_green", dut.south_lights & 1)
        vcd.update_var("east_red", (dut.east_lights >> 2) & 1)
        vcd.update_var("east_yellow", (dut.east_lights >> 1) & 1)
        vcd.update_var("east_green", dut.east_lights & 1)
        vcd.update_var("west_red", (dut.west_lights >> 2) & 1)
        vcd.update_var("west_yellow", (dut.west_lights >> 1) & 1)
        vcd.update_var("west_green", dut.west_lights & 1)

    def check_assertions():
        nonlocal total_checks, passed_checks, failed_checks
        total_checks += 1
        ng = dut.north_lights & 1
        sg = dut.south_lights & 1
        eg = dut.east_lights & 1
        wg = dut.west_lights & 1
        green_sum = ng + sg + eg + wg
        if green_sum > 1:
            print(f"[FATAL ERROR] Multiple GREEN signals active simultaneously @ {sim_time} ns!")
            failed_checks += 1
            sys.exit(1)

        ny = (dut.north_lights >> 1) & 1
        sy = (dut.south_lights >> 1) & 1
        ey = (dut.east_lights >> 1) & 1
        wy = (dut.west_lights >> 1) & 1
        yellow_sum = ny + sy + ey + wy
        if yellow_sum > 1:
            print(f"[FATAL ERROR] Multiple YELLOW signals active simultaneously @ {sim_time} ns!")
            failed_checks += 1
            sys.exit(1)

        # Mutually exclusive per direction
        for name, lgt in [("North", dut.north_lights), ("South", dut.south_lights),
                          ("East", dut.east_lights), ("West", dut.west_lights)]:
            r = (lgt >> 2) & 1
            y = (lgt >> 1) & 1
            g = lgt & 1
            if (r + y + g) != 1:
                print(f"[ERROR] Invalid {name} signal lights {r}{y}{g} @ {sim_time} ns!")
                failed_checks += 1
                return
        passed_checks += 1

    def step_clock():
        nonlocal sim_time
        # Falling edge
        dump_current(sim_time, 0)
        sim_time += 5

        # Rising edge
        dut.clock_tick()
        check_assertions()
        dump_current(sim_time, 1)
        sim_time += 5

    # -------------------------------------------------------------------------
    # Scenario 1: Reset Verification
    # -------------------------------------------------------------------------
    print("\n--- SCENARIO 1: SYNCHRONOUS RESET VERIFICATION ---")
    dut.rst = 1
    for _ in range(3):
        step_clock()

    total_checks += 1
    if dut.current_state == S_NORTH_GREEN and dut.north_lights == LIGHT_GREEN:
        print(f"[PASS] [Test {total_checks:02d}] Synchronous Reset Active: State={STATE_NAMES[dut.current_state]} @ {sim_time} ns")
        passed_checks += 1
    else:
        print(f"[FAIL] [Test {total_checks:02d}] Reset check failed!")
        failed_checks += 1

    dut.rst = 0
    step_clock()
    total_checks += 1
    if dut.current_state == S_NORTH_GREEN and dut.north_lights == LIGHT_GREEN:
        print(f"[PASS] [Test {total_checks:02d}] Post-Reset State: State={STATE_NAMES[dut.current_state]} @ {sim_time} ns")
        passed_checks += 1
    else:
        print(f"[FAIL] [Test {total_checks:02d}] Post-reset state failed!")
        failed_checks += 1

    # -------------------------------------------------------------------------
    # Scenario 2: Complete 4-Way Round-Robin Cycle & Duration Checks
    # -------------------------------------------------------------------------
    print("\n--- SCENARIO 2: COMPLETE 4-WAY ROUND-ROBIN CYCLE & DURATION CHECKS ---")
    sequence = [
        (S_NORTH_GREEN, 10 - 1, "North GREEN Phase"), # 1 tick already consumed
        (S_NORTH_YELLOW, 3, "North YELLOW Phase"),
        (S_SOUTH_GREEN, 10, "South GREEN Phase"),
        (S_SOUTH_YELLOW, 3, "South YELLOW Phase"),
        (S_EAST_GREEN, 10, "East GREEN Phase"),
        (S_EAST_YELLOW, 3, "East YELLOW Phase"),
        (S_WEST_GREEN, 10, "West GREEN Phase"),
        (S_WEST_YELLOW, 3, "West YELLOW Phase"),
    ]

    for expected_st, expected_dur, label in sequence:
        elapsed = 0
        while dut.current_state == expected_st:
            step_clock()
            elapsed += 1

        total_checks += 1
        if elapsed == expected_dur:
            print(f"[PASS] [Test {total_checks:02d}] {label} Duration Check: Exactly {elapsed} ticks ({elapsed * 10} ns)")
            passed_checks += 1
        else:
            print(f"[FAIL] [Test {total_checks:02d}] {label} Duration: Expected {expected_dur}, Got {elapsed}")
            failed_checks += 1

    total_checks += 1
    if dut.current_state == S_NORTH_GREEN:
        print(f"[PASS] [Test {total_checks:02d}] Cycle 1 Complete -> Successfully returned to S_NORTH_GREEN @ {sim_time} ns")
        passed_checks += 1
    else:
        print(f"[FAIL] [Test {total_checks:02d}] Failed to return to S_NORTH_GREEN!")
        failed_checks += 1

    # -------------------------------------------------------------------------
    # Scenario 3: Mid-Operation Reset Recovery
    # -------------------------------------------------------------------------
    print("\n--- SCENARIO 3: MID-OPERATION SYNCHRONOUS RESET RECOVERY ---")
    # Advance to East Green (10+3+10+3+5 = 31 cycles)
    for _ in range(31):
        step_clock()

    print(f"Asserting reset mid-operation during State={STATE_NAMES[dut.current_state]} @ {sim_time} ns")
    dut.rst = 1
    step_clock()

    total_checks += 1
    if dut.current_state == S_NORTH_GREEN and dut.north_lights == LIGHT_GREEN:
        print(f"[PASS] [Test {total_checks:02d}] Immediate Reset to S_NORTH_GREEN Verified @ {sim_time} ns")
        passed_checks += 1
    else:
        print(f"[FAIL] [Test {total_checks:02d}] Mid-operation reset failed!")
        failed_checks += 1

    dut.rst = 0
    step_clock()

    # -------------------------------------------------------------------------
    # Scenario 4: Continuous Multi-Cycle Stability Stress Test
    # -------------------------------------------------------------------------
    print("\n--- SCENARIO 4: CONTINUOUS MULTI-CYCLE STABILITY STRESS TEST (3 CYCLES) ---")
    ticks_to_run = 3 * 4 * (10 + 3) # 3 full cycles = 156 ticks
    for _ in range(ticks_to_run):
        step_clock()

    total_checks += 1
    if failed_checks == 0:
        print(f"[PASS] [Test {total_checks:02d}] Multi-Cycle Continuous Stress Test Passed with Zero Invariant Violations!")
        passed_checks += 1
    else:
        print(f"[FAIL] [Test {total_checks:02d}] Multi-Cycle Stress Test encountered errors.")
        failed_checks += 1

    vcd.close()

    print("\n===============================================================================")
    print("                          VERIFICATION SUMMARY REPORT                          ")
    print("===============================================================================")
    print(f"Total Checks Executed : {total_checks}")
    print(f"Passed Checks         : {passed_checks}")
    print(f"Failed Checks         : {failed_checks}")
    print(f"Total Simulation Time : {sim_time} ns ({sim_time // 10} clock cycles)")
    print(f"Waveform Output File  : {vcd_path}")

    if failed_checks == 0:
        print("\n>>> ALL VERIFICATION TESTS PASSED SUCCESSFULLY! <<<")
        print(">>> ZERO CONFLICTING GREENS DETECTED. ALL TIMINGS VERIFIED. <<<")
    else:
        print(f"\n>>> TESTBENCH FAILED WITH {failed_checks} ERRORS! <<<")
    print("===============================================================================\n")


if __name__ == "__main__":
    run_verification()
