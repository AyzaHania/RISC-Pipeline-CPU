`timescale 1ns/1ps

module register_file (
         input clk,
         input reg_write,
         input [4:0] rs1,
         input [4:0] rs2,
         input [4:0] rd,
         output [31:0] read_data1,
         output [31:0] read_data2,
         input [31:0] write_data
);

    reg [31:0] registers [0:31];

    assign read_data1 = (rs1==0) ? 32'b0 : registers[rs1];
    assign read_data2 = (rs2==0) ? 32'b0 : registers[rs2];

    always @(posedge clk) begin
        if (reg_write && rd != 0)
            registers[rd] <= write_data;

    end 
endmodule

