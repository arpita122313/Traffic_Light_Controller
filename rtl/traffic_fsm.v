// =============================================================================
// Project       : Four-Way Traffic Light Controller
// Module        : traffic_fsm
// Description   : 8-State Moore Finite State Machine controlling sequential
//                 traffic phases across North, South, East, and West directions.
//                 Adheres to standard 3-process clean synthesizable FSM style.
// Standard      : IEEE 1364-2001 Verilog HDL
// Author        : VLSI RTL Design Team
// =============================================================================

	imescale 1ns / 1ps

module traffic_fsm (
    input  wire       clk,          // System clock
    input  wire       rst,          // Synchronous active-high reset
    input  wire       timer_done,   // Indicates current phase time has expired
    output reg  [2:0] current_state,// Current active state output
    output wire       duration_sel, // 0 = GREEN duration, 1 = YELLOW duration
    output wire       timer_clear   // Clear pulse when state transitions
);

    // State Encoding Parameters (3-bit Gray / Binary encoding)
    localparam [2:0] S_NORTH_GREEN  = 3'b000;
    localparam [2:0] S_NORTH_YELLOW = 3'b001;
    localparam [2:0] S_SOUTH_GREEN  = 3'b010;
    localparam [2:0] S_SOUTH_YELLOW = 3'b011;
    localparam [2:0] S_EAST_GREEN   = 3'b100;
    localparam [2:0] S_EAST_YELLOW  = 3'b101;
    localparam [2:0] S_WEST_GREEN   = 3'b110;
    localparam [2:0] S_WEST_YELLOW  = 3'b111;

    // Internal next state register
    reg [2:0] next_state;

    // -------------------------------------------------------------------------
    // Sequential Process: State Register Update with Synchronous Reset
    // -------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            current_state <= S_NORTH_GREEN;
        end else begin
            current_state <= next_state;
        end
    end

    // -------------------------------------------------------------------------
    // Combinational Process: Next-State Transition Logic
    // -------------------------------------------------------------------------
    always @(*) begin
        // Default assignment to avoid latch inference
        next_state = current_state;

        case (current_state)
            S_NORTH_GREEN: begin
                if (timer_done)
                    next_state = S_NORTH_YELLOW;
                else
                    next_state = S_NORTH_GREEN;
            end

            S_NORTH_YELLOW: begin
                if (timer_done)
                    next_state = S_SOUTH_GREEN;
                else
                    next_state = S_NORTH_YELLOW;
            end

            S_SOUTH_GREEN: begin
                if (timer_done)
                    next_state = S_SOUTH_YELLOW;
                else
                    next_state = S_SOUTH_GREEN;
            end

            S_SOUTH_YELLOW: begin
                if (timer_done)
                    next_state = S_EAST_GREEN;
                else
                    next_state = S_SOUTH_YELLOW;
            end

            S_EAST_GREEN: begin
                if (timer_done)
                    next_state = S_EAST_YELLOW;
                else
                    next_state = S_EAST_GREEN;
            end

            S_EAST_YELLOW: begin
                if (timer_done)
                    next_state = S_WEST_GREEN;
                else
                    next_state = S_EAST_YELLOW;
            end

            S_WEST_GREEN: begin
                if (timer_done)
                    next_state = S_WEST_YELLOW;
                else
                    next_state = S_WEST_GREEN;
            end

            S_WEST_YELLOW: begin
                if (timer_done)
                    next_state = S_NORTH_GREEN;
                else
                    next_state = S_WEST_YELLOW;
            end

            default: begin
                next_state = S_NORTH_GREEN;
            end
        endcase
    end

    // -------------------------------------------------------------------------
    // Output Logic: Moore Control Signals
    // -------------------------------------------------------------------------
    // Bit 0 is 1 in all YELLOW states (3'b001, 3'b011, 3'b101, 3'b111)
    // and 0 in all GREEN states (3'b000, 3'b010, 3'b100, 3'b110).
    assign duration_sel = current_state[0];

    // Assert timer_clear when timer_done triggers a state transition
    assign timer_clear  = timer_done;

endmodule
