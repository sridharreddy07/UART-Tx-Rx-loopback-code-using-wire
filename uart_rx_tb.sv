`timescale 1ns/1ps
module uart_rx_tb;

    logic clk;
    logic rst;
    logic rx;
    logic [7:0] data_out;
    logic data_valid;

    // Instantiate RX
    uart_rx dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data_out(data_out),
        .data_valid(data_valid)
    );

    // 50 MHz clock
    always #10 clk = ~clk;

    // Bit time for 9600 baud (5208 cycles × 20ns)
    localparam int BIT_TIME = 5208 * 20;

    // UART send task
    task automatic send_uart_byte(input [7:0] tx_byte);
        integer i;
        begin
            // Start bit
            rx = 0;
            #(BIT_TIME);

            // Data bits (LSB first)
            for (i = 0; i < 8; i++) begin
                rx = tx_byte[i];
                #(BIT_TIME);
            end

            // Stop bit
            rx = 1;
            #(BIT_TIME);
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        rx  = 1;  // idle high

        #200 rst = 0;

        // Send byte 0xA5
        #500;
        send_uart_byte(8'b10101010);

        // Wait long enough for RX to finish
        #2_000_000;

        if (data_valid)
            $display("RX received byte: %h at time %t", data_out, $time);
        else
            $display("ERROR: No data received");

        #1000;
        $finish;
    end

endmodule
