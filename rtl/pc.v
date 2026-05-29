`timescale 1ns/1ps

module pc (
    input             clk,
    input             rst,
    input      [31:0] next_pc,
    output reg [31:0] pc_out
);

    always @(posedge clk) begin
        if (rst)
            pc_out <= 32'b0;
        else
            pc_out <= next_pc;
    end

endmodule
