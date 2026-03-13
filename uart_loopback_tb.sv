`timescale 1ns/1ps

module uart_loopback_tb;

logic clk;
logic rst;
logic tx_start;
logic [7:0] data_in;
logic [7:0] data_out;
logic data_valid;

// instantiate top module
uart_loopback dut(
    .clk(clk),
    .rst(rst),
    .tx_start(tx_start),
    .data_in(data_in),
    .data_out(data_out),
    .data_valid(data_valid)
);

// 50 MHz clock
always #10 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    tx_start = 0;
    data_in = 8'b10101010;

    #50 rst = 0;

    // Send first byte
    #20 tx_start = 1;
    #20 tx_start = 0;

    // Wait long enough to see full byte transmission
    #2_000_000;

    $finish;
end

endmodule
