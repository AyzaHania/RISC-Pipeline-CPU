`timescale 1ns/1ps

module hazard_detection (
    // ID/EX stage info
    input       idex_mem_read,
    input [4:0] idex_rd,

    // IF/ID stage info 
    input [4:0] ifid_rs1,
    input [4:0] ifid_rs2,

    // outputs
    output reg  stall,
    output reg  pc_write,      // 0 = freeze PC
    output reg  ifid_write     // 0 = freeze IF/ID register
);

    always @(*) begin
        // detect load-use hazard
        if (idex_mem_read &&
            idex_rd != 0 &&
            (idex_rd == ifid_rs1 || idex_rd == ifid_rs2))
        begin
            stall      = 1;  // insert bubble into ID/EX
            pc_write   = 0;  // freeze PC
            ifid_write = 0;  // freeze IF/ID register
        end
        else begin
            stall      = 0;  // no hazard
            pc_write   = 1;  // PC increments normally
            ifid_write = 1;  // IF/ID updates normally
        end
    end

endmodule
