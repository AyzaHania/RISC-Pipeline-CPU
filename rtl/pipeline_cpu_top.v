`timescale 1ns/1ps

module pipeline_cpu_top (
    input clk,
    input rst
);

// ── IF stage wires ──
    wire [31:0] pc_out;
    wire [31:0] pc_plus4;
    wire [31:0] next_pc;
    wire [31:0] if_instruction;

    // ── IF/ID register outputs ──
    wire [31:0] id_instruction;
    wire [31:0] id_pc_plus4;

    // ── ID stage wires ──
    wire [5:0]  id_opcode  = id_instruction[31:26];
    wire [4:0]  id_rs1     = id_instruction[25:21];
    wire [4:0]  id_rs2     = id_instruction[20:16];
    wire [4:0]  id_rd      = id_instruction[15:11];
    wire [15:0] id_imm     = id_instruction[15:0];
    wire [5:0]  id_funct   = id_instruction[5:0];

    // ── Control signals ──
    wire        id_reg_write, id_mem_read;
    wire        id_mem_write, id_mem_to_reg;
    wire        id_alu_src,   id_branch;
    wire [1:0]  id_alu_op;

    // ── Register file outputs ──
    wire [31:0] id_read_data1, id_read_data2;
    wire [31:0] id_sign_ext_imm;

    // ── Hazard detection outputs ──
    wire        stall, pc_write, ifid_write;

    // ── ID/EX register outputs ──
    wire        ex_reg_write, ex_mem_read;
    wire        ex_mem_write, ex_mem_to_reg;
    wire        ex_alu_src,   ex_branch;
    wire [1:0]  ex_alu_op;
    wire [31:0] ex_pc_plus4;
    wire [31:0] ex_read_data1, ex_read_data2;
    wire [31:0] ex_sign_ext_imm;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;

    // ── EX stage wires ──
    wire [2:0]  ex_alu_ctrl;
    wire [31:0] ex_alu_result;
    wire        ex_zero;
    wire [31:0] ex_branch_addr;
    wire [31:0] ex_alu_a_input;
    wire [31:0] ex_alu_b_input;
    wire [31:0] ex_alu_b_mux;
    wire [1:0]  forwardA, forwardB;

    // ── EX/MEM register outputs ──
    wire        mem_reg_write, mem_mem_read;
    wire        mem_mem_write, mem_mem_to_reg;
    wire        mem_branch, mem_zero;
    wire [31:0] mem_alu_result;
    wire [31:0] mem_read_data2;
    wire [31:0] mem_branch_addr;
    wire [4:0]  mem_rd;

    // ── MEM stage wires ──
    wire [31:0] mem_read_data;
    wire        pc_src;

    // ── MEM/WB register outputs ──
    wire        wb_reg_write, wb_mem_to_reg;
    wire [31:0] wb_read_data, wb_alu_result;
    wire [4:0]  wb_rd;

    // ── WB stage wires ──
    wire [31:0] wb_write_back;

// PC calculations
    assign pc_plus4    = pc_out + 4;
    assign ex_branch_addr = ex_pc_plus4 + (ex_sign_ext_imm << 2);
    assign pc_src      = mem_branch & mem_zero;

    // forwarding MUXes for ALU inputs
    assign ex_alu_a_input = (forwardA == 2'b10) ? mem_alu_result :
                            (forwardA == 2'b01) ? wb_write_back  :
                            ex_read_data1;

    assign ex_alu_b_mux   = (forwardB == 2'b10) ? mem_alu_result :
                            (forwardB == 2'b01) ? wb_write_back  :
                            ex_read_data2;

    // MUX1 — ALU src (register vs immediate)
    assign ex_alu_b_input = ex_alu_src ? ex_sign_ext_imm : ex_alu_b_mux;

    // WB writeback MUX
    assign wb_write_back  = wb_mem_to_reg ? wb_read_data : wb_alu_result;

    // PC source MUX
    assign next_pc = pc_src ? mem_branch_addr : pc_plus4;

// 1. Program Counter
    pc PC (
        .clk(clk), .rst(rst),
        .next_pc(next_pc),
        .pc_out(pc_out)
    );

    // 2. Instruction Memory
    instruction_memory IMEM (
        .addr(pc_out),
        .instruction(if_instruction)
    );

    // 3. IF/ID Pipeline Register
    if_id_reg IFID (
        .clk(clk), .rst(rst),
        .stall(!ifid_write),
        .flush(pc_src),
        .if_pc_plus4(pc_plus4),
        .if_instruction(if_instruction),
        .id_pc_plus4(id_pc_plus4),
        .id_instruction(id_instruction)
    );

    // 4. Control Unit
    control_unit CU (
        .opcode(id_opcode),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .alu_src(id_alu_src),
        .branch(id_branch),
        .alu_op(id_alu_op)
    );

    // 5. Hazard Detection Unit
    hazard_detection HDU (
        .idex_mem_read(ex_mem_read),
        .idex_rd(ex_rd),
        .ifid_rs1(id_rs1),
        .ifid_rs2(id_rs2),
        .stall(stall),
        .pc_write(pc_write),
        .ifid_write(ifid_write)
    );

    // 6. Register File
    register_file RF (
        .clk(clk),
        .reg_write(wb_reg_write),
        .rs1(id_rs1),
        .rs2(id_rs2),
        .rd(wb_rd),
        .write_data(wb_write_back),
        .read_data1(id_read_data1),
        .read_data2(id_read_data2)
    );

    // 7. Sign Extend
    sign_extend SE (
        .in(id_imm),
        .out(id_sign_ext_imm)
    );

    // 8. ID/EX Pipeline Register
    id_ex_reg IDEX (
        .clk(clk), .rst(rst),
        .flush(stall),
        .id_reg_write(id_reg_write),
        .id_mem_read(id_mem_read),
        .id_mem_write(id_mem_write),
        .id_mem_to_reg(id_mem_to_reg),
        .id_alu_src(id_alu_src),
        .id_branch(id_branch),
        .id_alu_op(id_alu_op),
        .id_pc_plus4(id_pc_plus4),
        .id_read_data1(id_read_data1),
        .id_read_data2(id_read_data2),
        .id_sign_ext_imm(id_sign_ext_imm),
        .id_rs1(id_rs1),
        .id_rs2(id_rs2),
        .id_rd(id_rd),
        .ex_reg_write(ex_reg_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_alu_src(ex_alu_src),
        .ex_branch(ex_branch),
        .ex_alu_op(ex_alu_op),
        .ex_pc_plus4(ex_pc_plus4),
        .ex_read_data1(ex_read_data1),
        .ex_read_data2(ex_read_data2),
        .ex_sign_ext_imm(ex_sign_ext_imm),
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .ex_rd(ex_rd)
    );

    // 9. Forwarding Unit
    forwarding_unit FWD (
        .ex_rs1(ex_rs1),
        .ex_rs2(ex_rs2),
        .exmem_reg_write(mem_reg_write),
        .exmem_rd(mem_rd),
        .memwb_reg_write(wb_reg_write),
        .memwb_rd(wb_rd),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    // 10. ALU Control
    alu_control ALUCTRL (
        .alu_op(ex_alu_op),
        .funct(id_funct),
        .alu_ctrl(ex_alu_ctrl)
    );

    // 11. ALU
    alu ALU (
        .a(ex_alu_a_input),
        .b(ex_alu_b_input),
        .alu_control(ex_alu_ctrl),
        .result(ex_alu_result),
        .zero(ex_zero)
    );

    // 12. EX/MEM Pipeline Register
    ex_mem_reg EXMEM (
        .clk(clk), .rst(rst),
        .ex_reg_write(ex_reg_write),
        .ex_mem_read(ex_mem_read),
        .ex_mem_write(ex_mem_write),
        .ex_mem_to_reg(ex_mem_to_reg),
        .ex_branch(ex_branch),
        .ex_zero(ex_zero),
        .ex_alu_result(ex_alu_result),
        .ex_read_data2(ex_alu_b_mux),
        .ex_branch_addr(ex_branch_addr),
        .ex_rd(ex_rd),
        .mem_reg_write(mem_reg_write),
        .mem_mem_read(mem_mem_read),
        .mem_mem_write(mem_mem_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_branch(mem_branch),
        .mem_zero(mem_zero),
        .mem_alu_result(mem_alu_result),
        .mem_read_data2(mem_read_data2),
        .mem_branch_addr(mem_branch_addr),
        .mem_rd(mem_rd)
    );

    // 13. Data Memory
    data_memory DMEM (
        .clk(clk),
        .we(mem_mem_write),
        .addr(mem_alu_result),
        .write_data(mem_read_data2),
        .read_data(mem_read_data)
    );

    // 14. MEM/WB Pipeline Register
    mem_wb_reg MEMWB (
        .clk(clk), .rst(rst),
        .mem_reg_write(mem_reg_write),
        .mem_mem_to_reg(mem_mem_to_reg),
        .mem_read_data(mem_read_data),
        .mem_alu_result(mem_alu_result),
        .mem_rd(mem_rd),
        .wb_reg_write(wb_reg_write),
        .wb_mem_to_reg(wb_mem_to_reg),
        .wb_read_data(wb_read_data),
        .wb_alu_result(wb_alu_result),
        .wb_rd(wb_rd)
    );

endmodule
