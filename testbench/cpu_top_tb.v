`timescale 1ns/1ps

module cpu_top_tb;

    reg clk, rst;

    cpu_top CPU (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("../sim/cpu_wave.vcd");
        $dumpvars(0, cpu_top_tb);
        $dumpvars(0, CPU);
        $dumpvars(0, CPU.RF);

        clk = 0; rst = 1;
        #20;
        rst = 0;

        // load on negative edge — safely between clock edges
        @(negedge clk);
        CPU.RF.registers[1] = 32'd10;
        CPU.RF.registers[2] = 32'd20;

        @(posedge clk); #1;
        $display("Cycle 1: PC=%0d | instr=%h | R3=%0d (expected 30)",
            CPU.pc_out, CPU.instruction, CPU.RF.registers[3]);

        @(posedge clk); #1;
        $display("Cycle 2: PC=%0d | instr=%h | R5=%0d (expected 40)",
            CPU.pc_out, CPU.instruction, CPU.RF.registers[5]);

        @(posedge clk); #1;
        $display("Cycle 3: PC=%0d | instr=%h | R7=%0d (expected 70)",
            CPU.pc_out, CPU.instruction, CPU.RF.registers[7]);

        @(posedge clk); #1;
        $display("Cycle 4: PC=%0d | instr=%h | R9=%0d (expected 110)",
            CPU.pc_out, CPU.instruction, CPU.RF.registers[9]);

        $finish;
    end

endmodule
