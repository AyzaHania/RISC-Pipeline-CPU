`timescale 1ns/1ps

module control_unit_tb;

    reg [5:0] opcode;
    wire      reg_write, mem_read, mem_write;
    wire      mem_to_reg, alu_src, branch;
    wire [1:0] alu_op;

    control_unit uut (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch),
        .alu_op(alu_op)
    );

    initial begin
        $dumpfile("../sim/cu_wave.vcd");
        $dumpvars(0, control_unit_tb);

        // TEST 1: R-type
        opcode = 6'b000000; #10;
        $display("R-TYPE  | rw=%b mr=%b mw=%b m2r=%b as=%b br=%b aop=%b",
            reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, alu_op);

        // TEST 2: LOAD
        opcode = 6'b100011; #10;
        $display("LOAD    | rw=%b mr=%b mw=%b m2r=%b as=%b br=%b aop=%b",
            reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, alu_op);

        // TEST 3: STORE
        opcode = 6'b101011; #10;
        $display("STORE   | rw=%b mr=%b mw=%b m2r=%b as=%b br=%b aop=%b",
            reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, alu_op);

        // TEST 4: BRANCH
        opcode = 6'b000100; #10;
        $display("BRANCH  | rw=%b mr=%b mw=%b m2r=%b aop=%b br=%b aop=%b",
            reg_write, mem_read, mem_write, mem_to_reg, alu_src, branch, alu_op);

        $finish;
    end

endmodule
