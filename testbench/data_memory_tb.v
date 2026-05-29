`timescale 1ns/1ps

module data_memory_tb;

    reg         clk, we;
    reg  [31:0] addr, write_data;
    wire [31:0] read_data;

    data_memory uut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("../sim/dmem_wave.vcd");
        $dumpvars(0, data_memory_tb);

        clk = 0; we = 0;
        addr = 0; write_data = 0;

        // TEST 1: STORE 42 at address 0
        @(posedge clk);
        addr = 32'd0; write_data = 32'd42; we = 1;
        @(posedge clk);
        we = 0;
        #1;
        $display("LOAD addr=0: %0d (expected 42)", read_data);

        // TEST 2: STORE 100 at address 4
        @(posedge clk);
        addr = 32'd4; write_data = 32'd100; we = 1;
        @(posedge clk);
        we = 0;
        addr = 32'd4;
        #1;
        $display("LOAD addr=4: %0d (expected 100)", read_data);

        // TEST 3: STORE 255 at address 8
        @(posedge clk);
        addr = 32'd8; write_data = 32'd255; we = 1;
        @(posedge clk);
        we = 0;
        addr = 32'd8;
        #1;
        $display("LOAD addr=8: %0d (expected 255)", read_data);

        // TEST 4: read address 0 again — should still be 42
        addr = 32'd0;
        #1;
        $display("LOAD addr=0 again: %0d (expected 42)", read_data);

        $finish;
    end

endmodule
