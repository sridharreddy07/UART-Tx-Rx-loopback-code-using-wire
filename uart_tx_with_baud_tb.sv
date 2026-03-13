`timescale 1ns/1ps
module uart_tx_with_baud_tb;

    logic clk;
    logic rst;
    logic tx_start;
    logic [7:0] data_in;
    logic tx;
    logic busy;

    uart_tx_with_baud dut(
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

    // 50 MHz clock
    always #10 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        tx_start = 0;
        data_in = 8'b10101010;

        #50 rst = 0;

        // short pulse works now
        #20 tx_start = 1;
        #20 tx_start = 0;

        // run long enough to see full byte
        #1_200_000;

        $finish;
    end

endmodule
