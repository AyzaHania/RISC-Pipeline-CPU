`timescale 1ns/1ps

// ─── IF/ID Pipeline Register ───
module if_id_reg (
    input         clk,
    input         rst,
    input         stall,        // freeze if stall
    input         flush,        // clear if branch taken
    input  [31:0] if_pc_plus4,
    input  [31:0] if_instruction,
    output reg [31:0] id_pc_plus4,
    output reg [31:0] id_instruction
);
    always @(posedge clk) begin
        if (rst || flush) begin
            id_pc_plus4    <= 32'b0;
            id_instruction <= 32'b0;  // NOP
        end
        else if (!stall) begin
            id_pc_plus4    <= if_pc_plus4;
            id_instruction <= if_instruction;
        end
        // if stall → hold current values (do nothing)
    end
endmodule

// ─── ID/EX Pipeline Register ───
module id_ex_reg (
    input         clk,
    input         rst,
    input         flush,
    // control signals
    input         id_reg_write,
    input         id_mem_read,
    input         id_mem_write,
    input         id_mem_to_reg,
    input         id_alu_src,
    input         id_branch,
    input  [1:0]  id_alu_op,
    // data signals
    input  [31:0] id_pc_plus4,
    input  [31:0] id_read_data1,
    input  [31:0] id_read_data2,
    input  [31:0] id_sign_ext_imm,
    input  [4:0]  id_rs1,
    input  [4:0]  id_rs2,
    input  [4:0]  id_rd,
    // outputs
    output reg         ex_reg_write,
    output reg         ex_mem_read,
    output reg         ex_mem_write,
    output reg         ex_mem_to_reg,
    output reg         ex_alu_src,
    output reg         ex_branch,
    output reg  [1:0]  ex_alu_op,
    output reg  [31:0] ex_pc_plus4,
    output reg  [31:0] ex_read_data1,
    output reg  [31:0] ex_read_data2,
    output reg  [31:0] ex_sign_ext_imm,
    output reg  [4:0]  ex_rs1,
    output reg  [4:0]  ex_rs2,
    output reg  [4:0]  ex_rd
);
    always @(posedge clk) begin
        if (rst || flush) begin
            ex_reg_write   <= 0; ex_mem_read    <= 0;
            ex_mem_write   <= 0; ex_mem_to_reg  <= 0;
            ex_alu_src     <= 0; ex_branch      <= 0;
            ex_alu_op      <= 0; ex_pc_plus4    <= 0;
            ex_read_data1  <= 0; ex_read_data2  <= 0;
            ex_sign_ext_imm<= 0; ex_rs1         <= 0;
            ex_rs2         <= 0; ex_rd          <= 0;
        end
        else begin
            ex_reg_write   <= id_reg_write;
            ex_mem_read    <= id_mem_read;
            ex_mem_write   <= id_mem_write;
            ex_mem_to_reg  <= id_mem_to_reg;
            ex_alu_src     <= id_alu_src;
            ex_branch      <= id_branch;
            ex_alu_op      <= id_alu_op;
            ex_pc_plus4    <= id_pc_plus4;
            ex_read_data1  <= id_read_data1;
            ex_read_data2  <= id_read_data2;
            ex_sign_ext_imm<= id_sign_ext_imm;
            ex_rs1         <= id_rs1;
            ex_rs2         <= id_rs2;
            ex_rd          <= id_rd;
        end
    end
endmodule

// ─── EX/MEM Pipeline Register ───
module ex_mem_reg (
    input         clk,
    input         rst,
    // control signals
    input         ex_reg_write,
    input         ex_mem_read,
    input         ex_mem_write,
    input         ex_mem_to_reg,
    input         ex_branch,
    // data signals
    input         ex_zero,
    input  [31:0] ex_alu_result,
    input  [31:0] ex_read_data2,
    input  [31:0] ex_branch_addr,
    input  [4:0]  ex_rd,
    // outputs
    output reg         mem_reg_write,
    output reg         mem_mem_read,
    output reg         mem_mem_write,
    output reg         mem_mem_to_reg,
    output reg         mem_branch,
    output reg         mem_zero,
    output reg  [31:0] mem_alu_result,
    output reg  [31:0] mem_read_data2,
    output reg  [31:0] mem_branch_addr,
    output reg  [4:0]  mem_rd
);
    always @(posedge clk) begin
        if (rst) begin
            mem_reg_write  <= 0; mem_mem_read   <= 0;
            mem_mem_write  <= 0; mem_mem_to_reg <= 0;
            mem_branch     <= 0; mem_zero       <= 0;
            mem_alu_result <= 0; mem_read_data2 <= 0;
            mem_branch_addr<= 0; mem_rd         <= 0;
        end
        else begin
            mem_reg_write  <= ex_reg_write;
            mem_mem_read   <= ex_mem_read;
            mem_mem_write  <= ex_mem_write;
            mem_mem_to_reg <= ex_mem_to_reg;
            mem_branch     <= ex_branch;
            mem_zero       <= ex_zero;
            mem_alu_result <= ex_alu_result;
            mem_read_data2 <= ex_read_data2;
            mem_branch_addr<= ex_branch_addr;
            mem_rd         <= ex_rd;
        end
    end
endmodule

// ─── MEM/WB Pipeline Register ───
module mem_wb_reg (
    input         clk,
    input         rst,
    // control signals
    input         mem_reg_write,
    input         mem_mem_to_reg,
    // data signals
    input  [31:0] mem_read_data,
    input  [31:0] mem_alu_result,
    input  [4:0]  mem_rd,
    // outputs
    output reg         wb_reg_write,
    output reg         wb_mem_to_reg,
    output reg  [31:0] wb_read_data,
    output reg  [31:0] wb_alu_result,
    output reg  [4:0]  wb_rd
);
    always @(posedge clk) begin
        if (rst) begin
            wb_reg_write  <= 0; wb_mem_to_reg <= 0;
            wb_read_data  <= 0; wb_alu_result <= 0;
            wb_rd         <= 0;
        end
        else begin
            wb_reg_write  <= mem_reg_write;
            wb_mem_to_reg <= mem_mem_to_reg;
            wb_read_data  <= mem_read_data;
            wb_alu_result <= mem_alu_result;
            wb_rd         <= mem_rd;
        end
    end
endmodule
