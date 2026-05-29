`timescale 1ns/1ps

module sign_extend_tb;

    reg  [15:0] in;
    wire [31:0] out;

    sign_extend uut (
        .in(in),
        .out(out)
    );

    initial begin
        $dumpfile("../sim/se_wave.vcd");
        $dumpvars(0, sign_extend_tb);

        // TEST 1: positive number (4)
        in = 16'h0004; #10;
        $display("in=%h out=%h (expected 00000004)", in, out);

        // TEST 2: positive number (100)
        in = 16'h0064; #10;
        $display("in=%h out=%h (expected 00000064)", in, out);

        // TEST 3: negative number (-4)
        in = 16'hFFFC; #10;
        $display("in=%h out=%h (expected FFFFFFFC)", in, out);

        // TEST 4: negative number (-1)
        in = 16'hFFFF; #10;
        $display("in=%h out=%h (expected FFFFFFFF)", in, out);

        // TEST 5: zero
        in = 16'h0000; #10;
        $display("in=%h out=%h (expected 00000000)", in, out);

        $finish;
    end

endmodule
