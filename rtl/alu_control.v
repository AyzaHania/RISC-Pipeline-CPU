`timescale 1ns/1ps

module alu_control (
    input      [1:0] alu_op,
    input      [5:0] funct,
    output reg [2:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl = 3'b000;  // ADD for LOAD/STORE
            2'b01: alu_ctrl = 3'b001;  // SUB for BRANCH

            2'b10: begin               // R-type — check funct
                case (funct)
                    6'b100000: alu_ctrl = 3'b000; // ADD
                    6'b100010: alu_ctrl = 3'b001; // SUB
                    6'b100100: alu_ctrl = 3'b010; // AND
                    6'b100101: alu_ctrl = 3'b011; // OR
                    6'b100110: alu_ctrl = 3'b100; // XOR
                    default:   alu_ctrl = 3'b000;
                endcase
            end

            default: alu_ctrl = 3'b000;
        endcase
    end

endmodule
