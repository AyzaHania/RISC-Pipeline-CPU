`timescale 1ns/1ps

module cpu_top (
    input clk,
    input rst
);

    // PC wires
    wire [31:0] pc_out;
    wire [31:0] pc_plus4;
    wire [31:0] next_pc;

    // Instruction wires
    wire [31:0] instruction;

    // Instruction field slicing
    wire [5:0]  opcode = instruction[31:26];
    wire [4:0]  rs1    = instruction[25:21];
    wire [4:0]  rs2    = instruction[20:16];
    wire [4:0]  rd     = instruction[15:11];
    wire [15:0] imm    = instruction[15:0];

    // Control signals
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        mem_to_reg;
    wire        alu_src;
    wire        branch;
    wire [1:0]  alu_op;

    // Register file wires
    wire [31:0] read_data1;
    wire [31:0] read_data2;
    wire [31:0] write_back_data;

    // Sign extend wire
    wire [31:0] sign_extended_imm;

    // ALU wires
    wire [31:0] alu_result;
    wire        zero;

    // ALU source MUX wire
    wire [31:0] alu_b_input;

    // Data memory wire
    wire [31:0] mem_read_data;

    // Branch wires
    wire [31:0] branch_addr;
    wire        pc_src;

    wire [2:0] alu_ctrl;
    wire [5:0] funct = instruction[5:0];

    
    assign pc_plus4    = pc_out + 4;
    assign branch_addr = pc_plus4 + (sign_extended_imm << 2);
    assign pc_src      = branch & zero;


    // 1. Program Counter
    pc PC (
        .clk(clk),
        .rst(rst),
        .next_pc(next_pc),
        .pc_out(pc_out)
    );

    // 2. Instruction Memory
    instruction_memory IMEM (
        .addr(pc_out),
        .instruction(instruction)
    );

    // 3. Control Unit
    control_unit CU (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch),
        .alu_op(alu_op)
    );

    // 4. Register File
    register_file RF (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_back_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // 5. Sign Extend
    sign_extend SE (
        .in(imm),
        .out(sign_extended_imm)
    );

    // 6. MUX1 — ALU source
    mux_alu_src MUX1 (
        .reg_data(read_data2),
        .imm_data(sign_extended_imm),
        .alu_src(alu_src),
        .out(alu_b_input)
    );
// 6.5 ALU Control Unit
alu_control ALUCTRL (
    .alu_op(alu_op),
    .funct(funct),
    .alu_ctrl(alu_ctrl)
);

    // 7. ALU
    alu ALU (
        .a(read_data1),
        .b(alu_b_input),
        .alu_control(alu_ctrl),
        .result(alu_result),
        .zero(zero)
    );

    // 8. Data Memory
    data_memory DMEM (
        .clk(clk),
        .we(mem_write),
        .addr(alu_result),
        .write_data(read_data2),
        .read_data(mem_read_data)
    );

    // 9. MUX2 — Writeback
    mux_mem_to_reg MUX2 (
        .alu_result(alu_result),
        .mem_data(mem_read_data),
        .mem_to_reg(mem_to_reg),
        .out(write_back_data)
    );

    // 10. MUX3 — PC source
    mux_pc_src MUX3 (
        .pc_plus4(pc_plus4),
        .branch_addr(branch_addr),
        .pc_src(pc_src),
        .out(next_pc)
    );

endmodule
