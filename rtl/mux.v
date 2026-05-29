`timescale 1ns/1ps

// MUX 1 — ALU source selector
module mux_alu_src (
    input  [31:0] reg_data,
    input  [31:0] imm_data,
    input         alu_src,
    output [31:0] out
);
    assign out = (alu_src) ? imm_data : reg_data;
endmodule

// MUX 2 — Writeback selector
module mux_mem_to_reg (
    input  [31:0] alu_result,
    input  [31:0] mem_data,
    input         mem_to_reg,
    output [31:0] out
);
    assign out = (mem_to_reg) ? mem_data : alu_result;
endmodule

// MUX 3 — PC source selector
module mux_pc_src (
    input  [31:0] pc_plus4,
    input  [31:0] branch_addr,
    input         pc_src,
    output [31:0] out
);
    assign out = (pc_src) ? branch_addr : pc_plus4;
endmodule
