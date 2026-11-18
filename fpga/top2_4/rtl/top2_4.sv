// Top2_4: find max and second-largest of four signed INT8 lanes.
// Maps 1:1 to top2_4_demo/top2_4.c reference model.
module top2_4 (
    input  logic [31:0] packed_i,
    output logic [15:0] result
);
    logic signed [7:0] a, b, c, d;
    logic signed [7:0] a1, b1, c1, d1;
    logic signed [7:0] max_val, min_ac, max_bd, second_val;

    assign a = packed_i[7:0];
    assign b = packed_i[15:8];
    assign c = packed_i[23:16];
    assign d = packed_i[31:24];

    always_comb begin
        // (a1, b1) = sort_desc(a, b); (c1, d1) = sort_desc(c, d)
        if ($signed(a) >= $signed(b)) begin
            a1 = a; b1 = b;
        end else begin
            a1 = b; b1 = a;
        end
        if ($signed(c) >= $signed(d)) begin
            c1 = c; d1 = d;
        end else begin
            c1 = d; d1 = c;
        end

        // max = max(a1, c1)
        max_val = ($signed(a1) >= $signed(c1)) ? a1 : c1;
        // second = max(min(a1, c1), max(b1, d1))
        min_ac  = ($signed(a1) <  $signed(c1)) ? a1 : c1;
        max_bd  = ($signed(b1) >= $signed(d1)) ? b1 : d1;
        second_val = ($signed(min_ac) >= $signed(max_bd)) ? min_ac : max_bd;

        result = {second_val, max_val};
    end
endmodule
