// =============================================================================
// Project       : Four-Way Traffic Light Controller
// Module        : timer_counter
// Description   : Parameterized synchronous timer/counter module that counts
//                 clock ticks up to a specified target duration.
//                 Generates a single-cycle done indicator for FSM transitions.
// Standard      : IEEE 1364-2001 Verilog HDL
// Author        : VLSI RTL Design Team
// =============================================================================

	imescale 1ns / 1ps

module timer_counter #(
    parameter WIDTH = 8                     // Width of duration counter
)(
    input  wire             clk,            // System clock
    input  wire             rst,            // Synchronous active-high reset
    input  wire             timer_enable,   // Clock enable (1 tick per cycle / pulse)
    input  wire             timer_clear,    // Synchronous clear signal
    input  wire [WIDTH-1:0] target_ticks,   // Target count duration for current phase
    output wire             timer_done,     // Pulse asserted on final tick of duration
    output wire [WIDTH-1:0] count_out       // Current counter value for debug/monitoring
);

    // Internal count register
    reg [WIDTH-1:0] count_reg;

    // Synchronous counter logic with priority clear and enable
    always @(posedge clk) begin
        if (rst) begin
            count_reg <= {WIDTH{1'b0}};
        end else if (timer_clear) begin
            count_reg <= {WIDTH{1'b0}};
        end else if (timer_enable) begin
            if (count_reg >= target_ticks - 1'b1) begin
                count_reg <= {WIDTH{1'b0}};
            end else begin
                count_reg <= count_reg + 1'b1;
            end
        end
    end

    // Timer done indicator asserted when count reaches target_ticks - 1
    assign timer_done = (timer_enable && (count_reg >= target_ticks - 1'b1));
    assign count_out  = count_reg;

endmodule
