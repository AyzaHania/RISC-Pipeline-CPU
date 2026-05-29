`timescale 1ns/1ps

module forwarding_unit (
    // current EX stage register addresses
    input      [4:0] ex_rs1,
    input      [4:0] ex_rs2,

    // EX/MEM stage info
    input            exmem_reg_write,
    input      [4:0] exmem_rd,

    // MEM/WB stage info
    input            memwb_reg_write,
    input      [4:0] memwb_rd,

    // forwarding select outputs
    output reg [1:0] forwardA,
    output reg [1:0] forwardB
);

    always @(*) begin

        // ── ForwardA (ALU input A) ──
        // EX hazard — forward from EX/MEM
        if (exmem_reg_write &&
            exmem_rd != 0 &&
            exmem_rd == ex_rs1)
            forwardA = 2'b10;

        // MEM hazard — forward from MEM/WB
        else if (memwb_reg_write &&
                 memwb_rd != 0 &&
                 memwb_rd == ex_rs1)
            forwardA = 2'b01;

        // no hazard — use register file
        else
            forwardA = 2'b00;

        // ── ForwardB (ALU input B) ──
        // EX hazard — forward from EX/MEM
        if (exmem_reg_write &&
            exmem_rd != 0 &&
            exmem_rd == ex_rs2)
            forwardB = 2'b10;

        // MEM hazard — forward from MEM/WB
        else if (memwb_reg_write &&
                 memwb_rd != 0 &&
                 memwb_rd == ex_rs2)
            forwardB = 2'b01;

        // no hazard — use register file
        else
            forwardB = 2'b00;

    end

endmodule
