`timescale 1ns/1ps

module alu_tb;

    // inputs are reg in testbench (we drive them)
    reg [31:0] a, b;
    reg [2:0]  alu_control;

    // outputs are wire in testbench (we just observe)
    wire [31:0] result;
    wire zero;

    // instantiate your ALU
    alu uut (
        .a(a),
        .b(b),
        .alu_control(alu_control),
        .result(result),
        .zero(zero)
    );

    initial begin
        $dumpfile("sim/alu_wave.vcd");
        $dumpvars(0, alu_tb);

        // TEST 1: ADD 5 + 3 = 8
        a = 32'd5; b = 32'd3; alu_control = 3'b000;
        #10;
        $display("ADD: %0d + %0d = %0d | zero=%b", a, b, result, zero);

        // TEST 2: SUB 5 - 3 = 2
        a = 32'd5; b = 32'd3; alu_control = 3'b001;
        #10;
        $display("SUB: %0d - %0d = %0d | zero=%b", a, b, result, zero);

        // TEST 3: SUB 5 - 5 = 0 (zero flag should be 1)
        a = 32'd5; b = 32'd5; alu_control = 3'b001;
        #10;
        $display("SUB: %0d - %0d = %0d | zero=%b", a, b, result, zero);

        // TEST 4: AND
        a = 32'hFF; b = 32'h0F; alu_control = 3'b010;
        #10;
        $display("AND: %0h & %0h = %0h | zero=%b", a, b, result, zero);

        // TEST 5: OR
        a = 32'hF0; b = 32'h0F; alu_control = 3'b011;
        #10;
        $display("OR:  %0h | %0h = %0h | zero=%b", a, b, result, zero);

        // TEST 6: XOR
        a = 32'hFF; b = 32'hFF; alu_control = 3'b100;
        #10;
        $display("XOR: %0h ^ %0h = %0h | zero=%b", a, b, result, zero);

        $finish;
    end

endmodule
