
`timescale 1ns/1ps

module register_file_tb;

    reg         clk;
    reg         reg_write;
    reg  [4:0]  rs1, rs2, rd;
    reg  [31:0] write_data;
    wire [31:0] read_data1, read_data2;

    // instantiate register file
    register_file uut (
        .clk(clk),
        .reg_write(reg_write),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // clock generator — flips every 5ns
    always #5 clk = ~clk;

    initial begin
        $dumpfile("../sim/reg_wave.vcd");
        $dumpvars(0, register_file_tb);

        // initialize everything
        clk = 0;
        reg_write = 0;
        rs1 = 0; rs2 = 0; rd = 0;
        write_data = 0;

        // TEST 1: write 42 into R1
        @(posedge clk);
        rd = 5'd1; write_data = 32'd42; reg_write = 1;
        @(posedge clk);
        reg_write = 0;
        rs1 = 5'd1;
        #1;
        $display("R1 = %0d (expected 42)", read_data1);

        // TEST 2: write 100 into R2
        @(posedge clk);
        rd = 5'd2; write_data = 32'd100; reg_write = 1;
        @(posedge clk);
        reg_write = 0;
        rs1 = 5'd2;
        #1;
        $display("R2 = %0d (expected 100)", read_data1);

        // TEST 3: read R1 and R2 simultaneously
        rs1 = 5'd1; rs2 = 5'd2;
        #1;
        $display("R1=%0d R2=%0d (expected 42 and 100)", read_data1, read_data2);

        // TEST 4: try writing to R0 — should stay zero
        @(posedge clk);
        rd = 5'd0; write_data = 32'd999; reg_write = 1;
        @(posedge clk);
        reg_write = 0;
        rs1 = 5'd0;
        #1;
        $display("R0 = %0d (expected 0)", read_data1);

        // TEST 5: write 255 into R3
        @(posedge clk);
        rd = 5'd3; write_data = 32'd255; reg_write = 1;
        @(posedge clk);
        reg_write = 0;
        rs1 = 5'd3;
        #1;
        $display("R3 = %0d (expected 255)", read_data1);

        $finish;
    end

endmodule










        
