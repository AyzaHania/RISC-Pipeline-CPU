`timescale 1ns/1ps

module mux_tb;

    // MUX 1 signals
    reg  [31:0] reg_data, imm_data;
    reg         alu_src;
    wire [31:0] mux1_out;

    // MUX 2 signals
    reg  [31:0] alu_result, mem_data;
    reg         mem_to_reg;
    wire [31:0] mux2_out;

    // MUX 3 signals
    reg  [31:0] pc_plus4, branch_addr;
    reg         pc_src;
    wire [31:0] mux3_out;

    // instantiate all three
    mux_alu_src MUX1 (
        .reg_data(reg_data),
        .imm_data(imm_data),
        .alu_src(alu_src),
        .out(mux1_out)
    );

    mux_mem_to_reg MUX2 (
        .alu_result(alu_result),
        .mem_data(mem_data),
        .mem_to_reg(mem_to_reg),
        .out(mux2_out)
    );

    mux_pc_src MUX3 (
        .pc_plus4(pc_plus4),
        .branch_addr(branch_addr),
        .pc_src(pc_src),
        .out(mux3_out)
    );

    initial begin
        $dumpfile("../sim/mux_wave.vcd");
        $dumpvars(0, mux_tb);

        // TEST MUX1 — ALU source
        reg_data = 32'd10; imm_data = 32'd99;
        alu_src = 0; #10;
        $display("MUX1 alu_src=0: out=%0d (expected 10)", mux1_out);
        alu_src = 1; #10;
        $display("MUX1 alu_src=1: out=%0d (expected 99)", mux1_out);

        // TEST MUX2 — writeback
        alu_result = 32'd42; mem_data = 32'd77;
        mem_to_reg = 0; #10;
        $display("MUX2 mem_to_reg=0: out=%0d (expected 42)", mux2_out);
        mem_to_reg = 1; #10;
        $display("MUX2 mem_to_reg=1: out=%0d (expected 77)", mux2_out);

        // TEST MUX3 — PC source
        pc_plus4 = 32'd8; branch_addr = 32'd100;
        pc_src = 0; #10;
        $display("MUX3 pc_src=0: out=%0d (expected 8)",   mux3_out);
        pc_src = 1; #10;
        $display("MUX3 pc_src=1: out=%0d (expected 100)", mux3_out);

        $finish;
    end

endmodule
