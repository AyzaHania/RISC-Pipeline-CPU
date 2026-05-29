`timescale 1ns/1ps

module instruction_memory (
    input  [31:0] addr,
    output [31:0] instruction
);

    reg [7:0] mem [0:63];

    assign instruction = {mem[addr], mem[addr+1], mem[addr+2], mem[addr+3]};

    initial begin
    // ADD R3, R1, R2 → 32'h00221820
    mem[0]  = 8'h00; mem[1]  = 8'h22; mem[2]  = 8'h18; mem[3]  = 8'h20;
    // ADD R5, R3, R1 → 32'h00612820
    mem[4]  = 8'h00; mem[5]  = 8'h61; mem[6]  = 8'h28; mem[7]  = 8'h20;
    // ADD R7, R5, R3 → 32'h00A33820
    mem[8]  = 8'h00; mem[9]  = 8'hA3; mem[10] = 8'h38; mem[11] = 8'h20;
    // ADD R9, R7, R5 → 32'h00E54820
    mem[12] = 8'h00; mem[13] = 8'hE5; mem[14] = 8'h48; mem[15] = 8'h20;
end

endmodule
