// =============================================================================
// Project       : Four-Way Traffic Light Controller
// Module        : traffic_controller_tb
// Description   : Comprehensive self-checking verification testbench for the
//                 4-way Traffic Light Controller.
//                 Verifies reset recovery, state sequence progression, exact
//                 green and yellow phase durations, conflicting green prevention,
//                 and multi-cycle operational stability.
// Standard      : IEEE 1364-2001 Verilog HDL
// Author        : VLSI RTL Design & Verification Team
// =============================================================================

`timescale 1ns / 1ps

module traffic_controller_tb;

    // -------------------------------------------------------------------------
    // Testbench Parameters & Timing Constants
    // -------------------------------------------------------------------------
    parameter CLK_PERIOD      = 10; // 100 MHz clock (10 ns period)
    parameter TIMER_WIDTH     = 8;
    parameter GREEN_TICKS     = 10;
    parameter YELLOW_TICKS    = 3;
    parameter SIMULATION_MODE = 1;

    // FSM State Encodings
    localparam [2:0] S_NORTH_GREEN  = 3'b000;
    localparam [2:0] S_NORTH_YELLOW = 3'b001;
    localparam [2:0] S_SOUTH_GREEN  = 3'b010;
    localparam [2:0] S_SOUTH_YELLOW = 3'b011;
    localparam [2:0] S_EAST_GREEN   = 3'b100;
    localparam [2:0] S_EAST_YELLOW  = 3'b101;
    localparam [2:0] S_WEST_GREEN   = 3'b110;
    localparam [2:0] S_WEST_YELLOW  = 3'b111;

    // Light Encodings: {Red, Yellow, Green}
    localparam [2:0] LIGHT_RED    = 3'b100;
    localparam [2:0] LIGHT_YELLOW = 3'b010;
    localparam [2:0] LIGHT_GREEN  = 3'b001;

    // -------------------------------------------------------------------------
    // DUT Interface Signals
    // -------------------------------------------------------------------------
    reg                    clk;
    reg                    rst;

    wire                   north_red;
    wire                   north_yellow;
    wire                   north_green;
    wire [2:0]             north_lights;

    wire                   south_red;
    wire                   south_yellow;
    wire                   south_green;
    wire [2:0]             south_lights;

    wire                   east_red;
    wire                   east_yellow;
    wire                   east_green;
    wire [2:0]             east_lights;

    wire                   west_red;
    wire                   west_yellow;
    wire                   west_green;
    wire [2:0]             west_lights;

    wire [2:0]             state_out;
    wire [TIMER_WIDTH-1:0] time_remaining;

    // -------------------------------------------------------------------------
    // Testbench Bookkeeping & Verification Metrics
    // -------------------------------------------------------------------------
    integer total_tests  = 0;
    integer tests_passed = 0;
    integer tests_failed = 0;
    integer cycle_count  = 0;

    // -------------------------------------------------------------------------
    // Device Under Test (DUT) Instantiation
    // -------------------------------------------------------------------------
    traffic_controller_top #(
        .TIMER_WIDTH    (TIMER_WIDTH),
        .GREEN_TICKS    (GREEN_TICKS),
        .YELLOW_TICKS   (YELLOW_TICKS),
        .SIMULATION_MODE(SIMULATION_MODE)
    ) dut (
        .clk           (clk),
        .rst           (rst),

        .north_red     (north_red),
        .north_yellow  (north_yellow),
        .north_green   (north_green),
        .north_lights  (north_lights),

        .south_red     (south_red),
        .south_yellow  (south_yellow),
        .south_green   (south_green),
        .south_lights  (south_lights),

        .east_red      (east_red),
        .east_yellow   (east_yellow),
        .east_green    (east_green),
        .east_lights   (east_lights),

        .west_red      (west_red),
        .west_yellow   (west_yellow),
        .west_green    (west_green),
        .west_lights   (west_lights),

        .state_out     (state_out),
        .time_remaining(time_remaining)
    );

    // -------------------------------------------------------------------------
    // 100 MHz Clock Generation Process
    // -------------------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Cycle tracking
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
    end

    // -------------------------------------------------------------------------
    // Real-Time Safety Assertions
    // Verifies safety properties on EVERY clock edge.
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (!rst) begin
            // 1. Conflict Prevention: At most one direction may have GREEN active
            if ((north_green + south_green + east_green + west_green) > 1) begin
                $display("[FATAL ERROR] [SAFETY VIOLATION] @ %0t ns | Multiple GREEN signals active simultaneously!", $time);
                $display("       North_G=%b, South_G=%b, East_G=%b, West_G=%b",
                         north_green, south_green, east_green, west_green);
                tests_failed = tests_failed + 1;
                $finish;
            end

            // 2. Conflict Prevention: At most one direction may have YELLOW active
            if ((north_yellow + south_yellow + east_yellow + west_yellow) > 1) begin
                $display("[FATAL ERROR] [SAFETY VIOLATION] @ %0t ns | Multiple YELLOW signals active simultaneously!", $time);
                tests_failed = tests_failed + 1;
                $finish;
            end

            // 3. Mutually Exclusive State per Direction (Exactly 1 lamp ON per direction)
            if ((north_red + north_yellow + north_green) != 1) begin
                $display("[ERROR] @ %0t ns | Invalid North signal combination: R=%b, Y=%b, G=%b",
                         $time, north_red, north_yellow, north_green);
                tests_failed = tests_failed + 1;
            end

            if ((south_red + south_yellow + south_green) != 1) begin
                $display("[ERROR] @ %0t ns | Invalid South signal combination: R=%b, Y=%b, G=%b",
                         $time, south_red, south_yellow, south_green);
                tests_failed = tests_failed + 1;
            end

            if ((east_red + east_yellow + east_green) != 1) begin
                $display("[ERROR] @ %0t ns | Invalid East signal combination: R=%b, Y=%b, G=%b",
                         $time, east_red, east_yellow, east_green);
                tests_failed = tests_failed + 1;
            end

            if ((west_red + west_yellow + west_green) != 1) begin
                $display("[ERROR] @ %0t ns | Invalid West signal combination: R=%b, Y=%b, G=%b",
                         $time, west_red, west_yellow, west_green);
                tests_failed = tests_failed + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Helper Tasks for Test Verification
    // -------------------------------------------------------------------------
    task assert_phase(
        input [2:0]        expected_state,
        input [2:0]        exp_n,
        input [2:0]        exp_s,
        input [2:0]        exp_e,
        input [2:0]        exp_w,
        input [8*25-1:0]   test_name
    );
        begin
            total_tests = total_tests + 1;
            if (state_out === expected_state &&
                north_lights === exp_n &&
                south_lights === exp_s &&
                east_lights  === exp_e &&
                west_lights  === exp_w) begin
                $display("[PASS] [Test %02d] %s | State=%03b | N=%b S=%b E=%b W=%b @ %0t ns",
                         total_tests, test_name, state_out, north_lights, south_lights, east_lights, west_lights, $time);
                tests_passed = tests_passed + 1;
            end else begin
                $display("[FAIL] [Test %02d] %s @ %0t ns", total_tests, test_name, $time);
                $display("       Expected: State=%03b N=%b S=%b E=%b W=%b",
                         expected_state, exp_n, exp_s, exp_e, exp_w);
                $display("       Actual  : State=%03b N=%b S=%b E=%b W=%b",
                         state_out, north_lights, south_lights, east_lights, west_lights);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    // Measure exact cycle duration of current active state
    task wait_and_verify_duration(
        input [2:0]      state_to_measure,
        input integer    expected_duration_ticks,
        input [8*25-1:0] phase_label
    );
        integer elapsed_ticks;
        begin
            total_tests = total_tests + 1;
            elapsed_ticks = 0;

            // Wait while in the same state
            while (state_out === state_to_measure) begin
                @(posedge clk);
                elapsed_ticks = elapsed_ticks + 1;
            end

            if (elapsed_ticks == expected_duration_ticks) begin
                $display("[PASS] [Test %02d] %s Duration Check: Exactly %0d ticks (%0d ns)",
                         total_tests, phase_label, elapsed_ticks, elapsed_ticks * CLK_PERIOD);
                tests_passed = tests_passed + 1;
            end else begin
                $display("[FAIL] [Test %02d] %s Duration Check: Expected %0d ticks, Got %0d ticks!",
                         total_tests, phase_label, expected_duration_ticks, elapsed_ticks);
                tests_failed = tests_failed + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Verification Execution Sequence
    // -------------------------------------------------------------------------
    initial begin
        // Waveform dumping for Vivado / GTKWave inspection
        $dumpfile("traffic_waveform.vcd");
        $dumpvars(0, traffic_controller_tb);

        $display("===============================================================================");
        $display("       FOUR-WAY TRAFFIC LIGHT CONTROLLER - RTL VERIFICATION TESTBENCH          ");
        $display("===============================================================================");
        $display("Clock Frequency    : 100 MHz (Period = 10 ns)");
        $display("GREEN Duration     : %0d Ticks (%0d ns)", GREEN_TICKS, GREEN_TICKS * CLK_PERIOD);
        $display("YELLOW Duration    : %0d Ticks (%0d ns)", YELLOW_TICKS, YELLOW_TICKS * CLK_PERIOD);
        $display("Predefined Order   : North -> South -> East -> West");
        $display("-------------------------------------------------------------------------------");

        // ---------------------------------------------------------------------
        // Scenario 1: Reset Verification
        // ---------------------------------------------------------------------
        $display("
--- SCENARIO 1: SYNCHRONOUS RESET VERIFICATION ---");
        rst = 1'b1;
        repeat (3) @(posedge clk);
        #1; // Sample shortly after clock edge

        assert_phase(S_NORTH_GREEN, LIGHT_GREEN, LIGHT_RED, LIGHT_RED, LIGHT_RED,
                     "Synchronous Reset Active");

        // Release reset synchronously on negative edge
        @(negedge clk);
        rst = 1'b0;
        @(posedge clk);
        #1;

        assert_phase(S_NORTH_GREEN, LIGHT_GREEN, LIGHT_RED, LIGHT_RED, LIGHT_RED,
                     "Post-Reset Default State");

        // ---------------------------------------------------------------------
        // Scenario 2: Complete First Round-Robin Cycle Timing & Sequence
        // ---------------------------------------------------------------------
        $display("
--- SCENARIO 2: COMPLETE 4-WAY ROUND-ROBIN CYCLE & DURATION CHECKS ---");

        // 1. North Green Phase (we already consumed 1 tick post-reset)
        wait_and_verify_duration(S_NORTH_GREEN, GREEN_TICKS - 1, "North GREEN Phase");

        // 2. North Yellow Phase
        assert_phase(S_NORTH_YELLOW, LIGHT_YELLOW, LIGHT_RED, LIGHT_RED, LIGHT_RED,
                     "North YELLOW Phase Active");
        wait_and_verify_duration(S_NORTH_YELLOW, YELLOW_TICKS, "North YELLOW Phase");

        // 3. South Green Phase
        assert_phase(S_SOUTH_GREEN, LIGHT_RED, LIGHT_GREEN, LIGHT_RED, LIGHT_RED,
                     "South GREEN Phase Active");
        wait_and_verify_duration(S_SOUTH_GREEN, GREEN_TICKS, "South GREEN Phase");

        // 4. South Yellow Phase
        assert_phase(S_SOUTH_YELLOW, LIGHT_RED, LIGHT_YELLOW, LIGHT_RED, LIGHT_RED,
                     "South YELLOW Phase Active");
        wait_and_verify_duration(S_SOUTH_YELLOW, YELLOW_TICKS, "South YELLOW Phase");

        // 5. East Green Phase
        assert_phase(S_EAST_GREEN, LIGHT_RED, LIGHT_RED, LIGHT_GREEN, LIGHT_RED,
                     "East GREEN Phase Active");
        wait_and_verify_duration(S_EAST_GREEN, GREEN_TICKS, "East GREEN Phase");

        // 6. East Yellow Phase
        assert_phase(S_EAST_YELLOW, LIGHT_RED, LIGHT_RED, LIGHT_YELLOW, LIGHT_RED,
                     "East YELLOW Phase Active");
        wait_and_verify_duration(S_EAST_YELLOW, YELLOW_TICKS, "East YELLOW Phase");

        // 7. West Green Phase
        assert_phase(S_WEST_GREEN, LIGHT_RED, LIGHT_RED, LIGHT_RED, LIGHT_GREEN,
                     "West GREEN Phase Active");
        wait_and_verify_duration(S_WEST_GREEN, GREEN_TICKS, "West GREEN Phase");

        // 8. West Yellow Phase
        assert_phase(S_WEST_YELLOW, LIGHT_RED, LIGHT_RED, LIGHT_RED, LIGHT_YELLOW,
                     "West YELLOW Phase Active");
        wait_and_verify_duration(S_WEST_YELLOW, YELLOW_TICKS, "West YELLOW Phase");

        // 9. Return to North Green
        assert_phase(S_NORTH_GREEN, LIGHT_GREEN, LIGHT_RED, LIGHT_RED, LIGHT_RED,
                     "Cycle 1 Complete -> N_GREEN");

        // ---------------------------------------------------------------------
        // Scenario 3: Mid-Operation Reset Assertion (Corner Case)
        // ---------------------------------------------------------------------
        $display("
--- SCENARIO 3: MID-OPERATION SYNCHRONOUS RESET RECOVERY ---");
        // Let it advance into South Yellow
        repeat (GREEN_TICKS + YELLOW_TICKS + GREEN_TICKS + 1) @(posedge clk);
        $display("Asserting reset mid-operation at State=%03b @ %0t ns", state_out, $time);

        @(negedge clk);
        rst = 1'b1;
        @(posedge clk);
        #1;
        assert_phase(S_NORTH_GREEN, LIGHT_GREEN, LIGHT_RED, LIGHT_RED, LIGHT_RED,
                     "Immediate Reset to N_GREEN");

        @(negedge clk);
        rst = 1'b0;
        @(posedge clk);

        // ---------------------------------------------------------------------
        // Scenario 4: Continuous Multi-Cycle Stability Stress Test
        // ---------------------------------------------------------------------
        $display("
--- SCENARIO 4: CONTINUOUS MULTI-CYCLE STABILITY STRESS TEST (3 CYCLES) ---");
        // Run for 3 full round-robin cycles (8 states * (10+3) = 104 ticks * 3 = 312 ticks)
        repeat (3 * 4 * (GREEN_TICKS + YELLOW_TICKS)) @(posedge clk);

        total_tests = total_tests + 1;
        if (tests_failed == 0) begin
            $display("[PASS] [Test %02d] Multi-Cycle Continuous Stress Test Passed with Zero Invariant Violations!", total_tests);
            tests_passed = tests_passed + 1;
        end else begin
            $display("[FAIL] [Test %02d] Multi-Cycle Stress Test encountered errors.", total_tests);
            tests_failed = tests_failed + 1;
        end

        // ---------------------------------------------------------------------
        // Verification Summary Report
        // ---------------------------------------------------------------------
        $display("
===============================================================================");
        $display("                          VERIFICATION SUMMARY REPORT                          ");
        $display("===============================================================================");
        $display("Total Checks Executed : %0d", total_tests);
        $display("Passed Checks         : %0d", tests_passed);
        $display("Failed Checks         : %0d", tests_failed);
        $display("Total Simulation Time : %0t ns (%0d clock cycles)", $time, cycle_count);

        if (tests_failed == 0) begin
            $display("
>>> ALL VERIFICATION TESTS PASSED SUCCESSFULLY! <<<");
            $display(">>> ZERO CONFLICTING GREENS DETECTED. ALL TIMINGS VERIFIED. <<<");
        end else begin
            $display("
>>> TESTBENCH FAILED WITH %0d ERRORS! <<< ", tests_failed);
        end
        $display("===============================================================================
");

        $finish;
    end

endmodule
