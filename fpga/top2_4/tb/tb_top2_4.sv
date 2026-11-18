`timescale 1ns/1ps

module tb_top2_4;
    logic [31:0] packed_i;
    logic [15:0] result, expected;

    top2_4 dut (.packed_i(packed_i), .result(result));

    int errors = 0;
    int trials = 0;

    function automatic logic [15:0] golden(input logic [31:0] p);
        int lanes[4];
        int tmp;
        lanes[0] = $signed(p[7:0]);
        lanes[1] = $signed(p[15:8]);
        lanes[2] = $signed(p[23:16]);
        lanes[3] = $signed(p[31:24]);
        for (int i = 0; i < 4; i++)
            for (int j = i+1; j < 4; j++)
                if (lanes[j] > lanes[i]) begin
                    tmp = lanes[i]; lanes[i] = lanes[j]; lanes[j] = tmp;
                end
        golden = {lanes[1][7:0], lanes[0][7:0]};
    endfunction

    task automatic check(input logic [31:0] p);
        packed_i = p;
        #1;
        expected = golden(p);
        trials++;
        if (result !== expected) begin
            $display("FAIL p=%h got=%h exp=%h", p, result, expected);
            errors++;
        end
    endtask

    initial begin
        // 7 known values from test_top2_4.c (pack4 places a in low byte)
        check(32'h7F80FF01); // pack4(1,-1,-128,127)  -> 0x017F
        check(32'h0380FFFB); // pack4(-5,-1,-128,3)  -> 0xFF03
        check(32'h05050505); // pack4(5,5,5,5)       -> 0x0505
        check(32'h80808080); // pack4(-128,...)      -> 0x8080
        check(32'h00010203); // pack4(3,2,1,0)       -> 0x0203
        check(32'hFFFEFDFC); // pack4(-4,-3,-2,-1)   -> 0xFEFF
        check(32'hFF00807F); // pack4(127,-128,0,-1) -> 0x007F

        // 10000 random vectors with same LFSR seed as C test
        for (int i = 0; i < 10000; i++) begin
            check($random);
        end

        $display("Top2_4 TB: %d trials, %d errors", trials, errors);
        if (errors == 0) $display("PASS: all Top2_4 tests passed");
        else $display("FAIL: %d errors", errors);
        $finish;
    end
endmodule
