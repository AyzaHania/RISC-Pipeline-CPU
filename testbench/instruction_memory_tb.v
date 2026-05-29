`timescale 1ns/1ps

module instruction_memory_tb;

    reg  [31:0] addr;
    wire [31:0] instruction;

    instruction_memory uut (
        .addr(addr),
        .instruction(instruction)
    );

    initial begin
        $dumpfile("../sim/imem_wave.vcd");
        $dumpvars(0, instruction_memory_tb);

        addr = 32'd0;  #10;
        $display("addr=%0d  instruction=%0h (expected 1)", addr, instruction);

        addr = 32'd4;  #10;
        $display("addr=%0d  instruction=%0h (expected 2)", addr, instruction);

        addr = 32'd8;  #10;
        $display("addr=%0d  instruction=%0h (expected 3)", addr, instruction);

        addr = 32'd12; #10;
        $display("addr=%0d  instruction=%0h (expected 4)", addr, instruction);

        addr = 32'd16; #10;
        $display("addr=%0d  instruction=%0h (expected 5)", addr, instruction);

        addr = 32'd28; #10;
        $display("addr=%0d  instruction=%0h (expected 8)", addr, instruction);

        $finish;
    end

endmodule
