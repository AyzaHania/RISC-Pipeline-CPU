`timescale 1ns/1ps

module data_memory (
    input         clk,
    input         we,
    input  [31:0] addr,
    input  [31:0] write_data,
    output [31:0] read_data
);

    // 64 locations each 8 bits
    reg [7:0] mem [0:63];

    // READ — combinational, instant
    assign read_data = {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]};

    // WRITE — sequential, on clock edge
    always @(posedge clk) begin
        if (we) begin
            mem[addr]   <= write_data[31:24];
            mem[addr+1] <= write_data[23:16];
            mem[addr+2] <= write_data[15:8];
            mem[addr+3] <= write_data[7:0];
        end
    end

endmodule
