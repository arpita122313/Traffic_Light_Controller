// =============================================================================
// Project       : Four-Way Traffic Light Controller
// Module        : signal_decoder
// Description   : Combinational decoder mapping the current FSM state to
//                 active Red, Yellow, and Green lights for North, South, East,
//                 and West directions. Guarantees mutual exclusion of Green.
// Standard      : IEEE 1364-2001 Verilog HDL
// Author        : VLSI RTL Design Team
// =============================================================================

	imescale 1ns / 1ps

module signal_decoder (
    input  wire [2:0] current_state, // FSM state input

    // North direction lights
    output wire       north_red,
    output wire       north_yellow,
    output wire       north_green,
    output wire [2:0] north_lights,  // Vector: {Red, Yellow, Green}

    // South direction lights
    output wire       south_red,
    output wire       south_yellow,
    output wire       south_green,
    output wire [2:0] south_lights,  // Vector: {Red, Yellow, Green}

    // East direction lights
    output wire       east_red,
    output wire       east_yellow,
    output wire       east_green,
    output wire [2:0] east_lights,   // Vector: {Red, Yellow, Green}

    // West direction lights
    output wire       west_red,
    output wire       west_yellow,
    output wire       west_green,
    output wire [2:0] west_lights    // Vector: {Red, Yellow, Green}
);

    // State Constants matching traffic_fsm
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

    reg [2:0] n_reg;
    reg [2:0] s_reg;
    reg [2:0] e_reg;
    reg [2:0] w_reg;

    always @(*) begin
        // Default safe condition: All directions RED
        n_reg = LIGHT_RED;
        s_reg = LIGHT_RED;
        e_reg = LIGHT_RED;
        w_reg = LIGHT_RED;

        case (current_state)
            S_NORTH_GREEN: begin
                n_reg = LIGHT_GREEN;
                s_reg = LIGHT_RED;
                e_reg = LIGHT_RED;
                w_reg = LIGHT_RED;
            end

            S_NORTH_YELLOW: begin
                n_reg = LIGHT_YELLOW;
                s_reg = LIGHT_RED;
                e_reg = LIGHT_RED;
                w_reg = LIGHT_RED;
            end

            S_SOUTH_GREEN: begin
                n_reg = LIGHT_RED;
                s_reg = LIGHT_GREEN;
                e_reg = LIGHT_RED;
                w_reg = LIGHT_RED;
            end

            S_SOUTH_YELLOW: begin
                n_reg = LIGHT_RED;
                s_reg = LIGHT_YELLOW;
                e_reg = LIGHT_RED;
                w_reg = LIGHT_RED;
            end

            S_EAST_GREEN: begin
                n_reg = LIGHT_RED;
                s_reg = LIGHT_RED;
                e_reg = LIGHT_GREEN;
                w_reg = LIGHT_RED;
            end

            S_EAST_YELLOW: begin
                n_reg = LIGHT_RED;
                s_reg = LIGHT_RED;
                e_reg = LIGHT_YELLOW;
                w_reg = LIGHT_RED;
            end

            S_WEST_GREEN: begin
                n_reg = LIGHT_RED;
                s_reg = LIGHT_RED;
                e_reg = LIGHT_RED;
                w_reg = LIGHT_GREEN;
            end

            S_WEST_YELLOW: begin
                n_reg = LIGHT_RED;
                s_reg = LIGHT_RED;
                e_reg = LIGHT_RED;
                w_reg = LIGHT_YELLOW;
            end

            default: begin
                n_reg = LIGHT_RED;
                s_reg = LIGHT_RED;
                e_reg = LIGHT_RED;
                w_reg = LIGHT_RED;
            end
        endcase
    end

    // Assign vector outputs
    assign north_lights = n_reg;
    assign south_lights = s_reg;
    assign east_lights  = e_reg;
    assign west_lights  = w_reg;

    // Assign individual scalar light outputs
    assign north_red    = n_reg[2];
    assign north_yellow = n_reg[1];
    assign north_green  = n_reg[0];

    assign south_red    = s_reg[2];
    assign south_yellow = s_reg[1];
    assign south_green  = s_reg[0];

    assign east_red     = e_reg[2];
    assign east_yellow  = e_reg[1];
    assign east_green   = e_reg[0];

    assign west_red     = w_reg[2];
    assign west_yellow  = w_reg[1];
    assign west_green   = w_reg[0];

endmodule
