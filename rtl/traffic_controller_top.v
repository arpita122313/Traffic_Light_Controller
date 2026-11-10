// =============================================================================
// Project       : Four-Way Traffic Light Controller
// Module        : traffic_controller_top
// Description   : Top-Level synthesizable module integrating the timer counter,
//                 8-state Moore FSM, and traffic signal output decoder.
//                 Includes parameterized clock-divider logic for hardware FPGA
//                 deployment (50MHz/100MHz to 1Hz) and high-speed simulation mode.
// Standard      : IEEE 1364-2001 Verilog HDL
// Author        : VLSI RTL Design Team
// =============================================================================

	imescale 1ns / 1ps

module traffic_controller_top #(
    parameter TIMER_WIDTH     = 8,          // Counter bit width (supports up to 255 ticks)
    parameter GREEN_TICKS     = 10,         // Duration of GREEN light in clock/tick periods
    parameter YELLOW_TICKS    = 3,          // Duration of YELLOW light in clock/tick periods
    parameter CLK_DIV_MAX     = 50_000_000, // Ratio to divide system clock to 1Hz
    parameter SIMULATION_MODE = 1           // 1: Direct clk ticks; 0: Clock divider active
)(
    input  wire                   clk,            // System clock (e.g. 50MHz / 100MHz)
    input  wire                   rst,            // Synchronous active-high reset

    // North direction lights
    output wire                   north_red,
    output wire                   north_yellow,
    output wire                   north_green,
    output wire [2:0]             north_lights,   // {Red, Yellow, Green}

    // South direction lights
    output wire                   south_red,
    output wire                   south_yellow,
    output wire                   south_green,
    output wire [2:0]             south_lights,   // {Red, Yellow, Green}

    // East direction lights
    output wire                   east_red,
    output wire                   east_yellow,
    output wire                   east_green,
    output wire [2:0]             east_lights,    // {Red, Yellow, Green}

    // West direction lights
    output wire                   west_red,
    output wire                   west_yellow,
    output wire                   west_green,
    output wire [2:0]             west_lights,    // {Red, Yellow, Green}

    // Status and diagnostic outputs
    output wire [2:0]             state_out,      // Current FSM state
    output wire [TIMER_WIDTH-1:0] time_remaining  // Countdown value in current phase
);

    // -------------------------------------------------------------------------
    // Internal Wires & Registers
    // -------------------------------------------------------------------------
    wire                   tick_enable;
    wire                   timer_done;
    wire                   timer_clear;
    wire                   duration_sel;
    wire [TIMER_WIDTH-1:0] target_ticks;
    wire [TIMER_WIDTH-1:0] current_count;

    // -------------------------------------------------------------------------
    // Clock Divider / Tick Generator
    // -------------------------------------------------------------------------
    generate
        if (SIMULATION_MODE == 1) begin : gen_sim_mode
            // In simulation, advance timer counter on every clock cycle
            assign tick_enable = 1'b1;
        end else begin : gen_hw_mode
            // In hardware FPGA mode, generate a 1-cycle enable pulse every 1 second
            reg [31:0] clk_div_cnt;
            reg        tick_reg;

            always @(posedge clk) begin
                if (rst) begin
                    clk_div_cnt <= 32'd0;
                    tick_reg    <= 1'b0;
                end else if (clk_div_cnt >= CLK_DIV_MAX - 1) begin
                    clk_div_cnt <= 32'd0;
                    tick_reg    <= 1'b1;
                end else begin
                    clk_div_cnt <= clk_div_cnt + 32'd1;
                    tick_reg    <= 1'b0;
                end
            end
            assign tick_enable = tick_reg;
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Dynamic Duration Selection
    // duration_sel = 0 -> GREEN_TICKS
    // duration_sel = 1 -> YELLOW_TICKS
    // -------------------------------------------------------------------------
    assign target_ticks = (duration_sel == 1'b1) ? YELLOW_TICKS[TIMER_WIDTH-1:0] :
                                                   GREEN_TICKS[TIMER_WIDTH-1:0];

    // Compute remaining time in current phase for monitoring / display
    assign time_remaining = (target_ticks > current_count) ?
                            (target_ticks - current_count) : {TIMER_WIDTH{1'b0}};

    // -------------------------------------------------------------------------
    // Timer Counter Instantiation
    // -------------------------------------------------------------------------
    timer_counter #(
        .WIDTH(TIMER_WIDTH)
    ) u_timer_counter (
        .clk         (clk),
        .rst         (rst),
        .timer_enable(tick_enable),
        .timer_clear (timer_clear),
        .target_ticks(target_ticks),
        .timer_done  (timer_done),
        .count_out   (current_count)
    );

    // -------------------------------------------------------------------------
    // Traffic FSM Instantiation
    // -------------------------------------------------------------------------
    traffic_fsm u_traffic_fsm (
        .clk          (clk),
        .rst          (rst),
        .timer_done   (timer_done),
        .current_state(state_out),
        .duration_sel (duration_sel),
        .timer_clear  (timer_clear)
    );

    // -------------------------------------------------------------------------
    // Signal Decoder Instantiation
    // -------------------------------------------------------------------------
    signal_decoder u_signal_decoder (
        .current_state(state_out),

        .north_red    (north_red),
        .north_yellow (north_yellow),
        .north_green  (north_green),
        .north_lights (north_lights),

        .south_red    (south_red),
        .south_yellow (south_yellow),
        .south_green  (south_green),
        .south_lights (south_lights),

        .east_red     (east_red),
        .east_yellow  (east_yellow),
        .east_green   (east_green),
        .east_lights  (east_lights),

        .west_red     (west_red),
        .west_yellow  (west_yellow),
        .west_green   (west_green),
        .west_lights  (west_lights)
    );

endmodule
