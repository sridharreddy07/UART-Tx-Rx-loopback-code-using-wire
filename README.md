here we are connecting two different files which is uart tx and uart rx files using wire and passing data through that wire.
Let me explain clearly here step by step
Let's go through the UART_Tx_with_baud
what is baud rate generator. In this problem we are using 50MHZ frequency with 9600 baud rate.
so there will be 9600 baud ticks each baud tick will carry 5208 clock cycles 50MHZ/9600 i.e 5208.
So each baud tick will appear for every 1/9600 =104166 ns
Coming to UART Frame structure 
start bit(TX)= 0 -> data bit = 8'hA5 -> stop bit =1 Total 10 bits 

always_ff @(posedge clk or posedge rst) begin
if (rst) begin
            baud_count <= 0;
            baud_tick <= 0;
        end else begin
            if (baud_count == BAUD_DIV-1) begin
                baud_count <= 0;
                baud_tick <= 1;
            end else begin
                baud_count <= baud_count + 1;
                baud_tick <= 0;
            end
For reset condition everything will be goes to zero
and when the count is till 5207 it will choose else condition, for 5207 pos edge cycles, then it will goes to if condition and again baud_count will be 0 and here baud_tick =1.
SO WHEN BAUD_TICK == 1;

always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            tx <= 1;        // idle high
            busy <= 0;
            shift_reg <= 0;
            bit_cnt <= 0;
            start_latched <= 0;
        end else begin
            // latch tx_start until baud_tick
            if (tx_start)
                start_latched <= 1;

THE RST WILL BE HIGH FOR FIRST 50NS AS WRITTEN IN TESTBENCH
THEN TX_START WILL BE HIGH FOR 20NS AS WRITTEN IN TESTBENCH.
SO start_latched <= 1; WILL BE 1
if (baud_tick) begin
                case(state)
                    IDLE: begin
                        tx <= 1;
                        busy <= 0;
                        if (start_latched) begin
                            shift_reg <= data_in;
                            busy <= 1;
                            state <= START;
                            start_latched <= 0;
                        end
                    end
                    START: begin
                        tx <= 0;       // start bit
                        bit_cnt <= 0;
                        state <= DATA;
                    end
                    DATA: begin
                        tx <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7)
                            state <= STOP;
                    end
                    STOP: begin
                        tx <= 1;       // stop bit
                        state <= IDLE;
                    end
                endcase
WE KNOW AS AFTER 5207 CLOCK CYCLES THE WHIH IS 104166 ns THE BAUD_TICK WILL BE 1
AND ENTER TO CASE STATEMENT WITH CASE: idle
WHERE TX=1 AND ENTER if (start_latched) begin WHERE ITS HIGH.
 SO DATA MOVES FROM DATA_IN  TO SHIFT_REG AS WE HAVE DATA_IN = 8'B10101010;
 AND STATE= START AND IT start_latched=0 AND IT NEVER GONNA ENTER THAT LOOP AND !=1:
 AFTER ENTERING START CASE TX=0 // START BIT
 BIT COUNT=0;
  DATA: begin
                        tx <= shift_reg[0];
                        shift_reg <= shift_reg >> 1;
                        bit_cnt <= bit_cnt + 1;
                        if (bit_cnt == 7)
                            state <= STOP;
                    end
here tx value is 0 after thatshift rig will do right shift means 1 bit right shift so next bit will be 1 if bit count is 1
here it will wait for 5207 positive cycyles again for one more baud tick till then it holds the data case and it will continue till bit count==7;
then it enters into stop case where tx=1 // stop bit and state== IDLE.

Now RX with baud
here we have to send the values to tx by bit by bite using send_tx_byte function waiting time is 5208*20 ns for each bit as it was written in the test bench.
So total 8 bits and for initial bit we have to wait for first baud_tick +700 ns  so for total it is (9*104160)= (937440+700)ns we have to wait for complete data transfer.
so we have to wait atleast 1/2 baud tick to begin checking receiving data so 938140 + 2604 = 940744 to check dout is correct or not then we can declare D_Valid as 1
so case (state)

                IDLE: begin
                    if (rx == 0) begin
                        state   <= START;
                        bit_cnt <= 0;
                    end
                end

                // Wait half bit time
                START: begin
                    if (bit_cnt == (BAUD_DIV/2)) begin
                        if (rx == 0) begin
                            state    <= DATA;
                            bit_cnt  <= 0;
                            data_idx <= 0;
                        end else begin
                            state <= IDLE; // false start
                        end
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end

                // Sample each bit every BAUD_DIV cycles
                DATA: begin
                    if (bit_cnt == BAUD_DIV-1) begin
                        bit_cnt   <= 0;
                        shift_reg <= {rx, shift_reg[7:1]};

                        if (data_idx == 7)
                            state <= STOP;
                        else
                            data_idx <= data_idx + 1;

                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end

                STOP: begin
                    if (bit_cnt == BAUD_DIV-1) begin
                        data_out   <= shift_reg;
                        data_valid <= 1;
                        state      <= IDLE;
                        bit_cnt    <= 0;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end

            endcase
in start case I have waited half time then i started ending data bit by bit as i have received in rx into shift reg

Here first I have send rx first byte then i have waited for 1/2 time to send the same value to shift reg.
If have waited more then half half time which is full time then there is high chance of data mismatch and code complex
why half time
Because the center is where:
- the signal is most stable
- noise is lowest
- jitter has minimal effect
- TX and RX clock mismatch has minimal effect
This is why every UART in the world samples at the center of each bit.

So after completion of this i have given data valid ass 1 in STop case. then enter into Idle state.

NOW WE ARE COMBINING TWO CODES WITH THE HELP OF ONE WIRE CALL TX_LINE.
SO WE HAVE TO WRITE LIKE THIS
IN TX_INSTANSTIATE
.tx(tx_line)

IN RX_INSTANSTIATE
.rx(tx_line)

here tx line which acts as rx line. and you the attached waveform.





