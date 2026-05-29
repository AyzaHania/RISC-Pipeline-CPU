`timescale 1ns/1ps

module pc_tb;

    reg clk, rst;
    wire [31:0] pc_out;

    pc uut (
        .clk(clk),
        .rst(rst),
        .pc_out(pc_out)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("../sim/pc_wave.vcd");
        $dumpvars(0, pc_tb);

        clk = 0; rst = 1;
        #10;

        rst = 0;
        #10; $display("PC = %0d (expected 4)",  pc_out);
        #10; $display("PC = %0d (expected 8)",  pc_out);
        #10; $display("PC = %0d (expected 12)", pc_out);
        #10; $display("PC = %0d (expected 16)", pc_out);
        #10; $display("PC = %0d (expected 20)", pc_out);

        rst = 1;
        #10; $display("PC = %0d (expected 0 after reset)", pc_out);

        $finish;
    end

endmodule
