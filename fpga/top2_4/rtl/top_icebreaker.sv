// iCEBreaker top: cycle through the 7 known test vectors, display
// max on LEDs[7:0] or second on buttons. Clock = 12 MHz on pin 35.
module top_icebreaker (
    input  logic       CLK,
    input  logic       BTN_N,      // user button (active low): held -> show second
    output logic [7:0] LED         // PMOD2 LEDs: 27,25,21,26,23 + PMOD1 45,47,48
);
    logic [31:0] packed_i;
    logic [15:0] result;

    top2_4 u_top2_4 (.packed_i(packed_i), .result(result));

    logic [25:0] counter;
    logic [2:0]  vec_idx;

    always_ff @(posedge CLK) begin
        counter <= counter + 1;
        if (counter == 26'd11_999_999) begin  // ~1 Hz at 12 MHz
            counter  <= 0;
            vec_idx  <= vec_idx + 1;
        end
    end

    // 7 known vectors from top2_4_demo/test_top2_4.c
    always_comb begin
        case (vec_idx)
            3'd0: packed_i = 32'h7F80FF01;
            3'd1: packed_i = 32'h0380FFFB;
            3'd2: packed_i = 32'h05050505;
            3'd3: packed_i = 32'h80808080;
            3'd4: packed_i = 32'h00010203;
            3'd5: packed_i = 32'hFFFEFDFC;
            default: packed_i = 32'hFF00807F;
        endcase
    end
    always_comb LED = (~BTN_N) ? result[15:8] : result[7:0];
endmodule
