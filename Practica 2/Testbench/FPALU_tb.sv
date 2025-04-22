module tb_FPalu;
    // Test signals
    logic [31:0] A, B, S;
    shortreal    rA, rB, rS;

    // Instantiate DUT
    FPALU dut(.A(A), .B(B), .S(S));
    assign rA = $bitstoshortreal(A);
    assign rB = $bitstoshortreal(B);
    assign rS = $bitstoshortreal(S);

    initial begin
        $display("Time |    A      -      B     =      S    |   rA      rB      rS");
        // 5.5 - 2.25 = 3.25
        A = 32'h40B00000; B = 32'h40100000; #1;
        $display("%0t | %h - %h = %h | %f - %f = %f", $time, A, B, S, rA, rB, rS);
        // 0.6 - 0.7 (round)
        A = 32'h3F19999A; B = 32'h3F2CCCCD; #1;
        $display("%0t | %h - %h = %h | %f - %f = %f", $time, A, B, S, rA, rB, rS);
        // 0 - 1.0 = -1.0
        A = 32'h00000000; B = 32'h3F800000; #1;
        $display("%0t | %h - %h = %h | %f - %f = %f", $time, A, B, S, rA, rB, rS);
        // INF - INF = NaN
        A = 32'h7F800000; B = 32'h7F800000; #1;
        $display("%0t | %h - %h = %h | rS = %f (NaN expected)", $time, A, B, S, rS);
        // resta de 2 números grandes (underflow) = - inf en hex es 0xFF800000
        A = 32'hff7fffff; B = 32'h7f7fffff; #1;
        $display("%0t | %h - %h = %h | rS = %f (underflow expected)", $time, A, B, S, rS);
        // Suma de 2 números grandes (overflow) = inf en hex es 0x7F800000
        A = 32'h7f7fffff; B = 32'hff7fffff; #1;
        $display("%0t | %h - %h = %h | rS = %f (overflow expected)", $time, A, B, S, rS);
        // NaN + 500 = NaN
        A = 32'h7f800800; B = 32'hc3fa0000; #1;
        $display("%0t | %h - %h = %h | rS = %f (NaN expected)", $time, A, B, S, rS);
        $finish;
    end
endmodule