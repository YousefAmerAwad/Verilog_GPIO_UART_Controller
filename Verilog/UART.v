module Baud_Rate_Generator(input wire clk_50MHZ,
		                       output wire rxclk_en,
		                       output wire txclk_en);
/*
  this module takes a 50MHZ clock as input and generates two outputs:
  txclk_en & rxclk_en which are connected to clken ports in both of them in the top module
  txclk_en is our baud rate which in this case is 115200
  rxclk_en is the oversampled baud rate = 16*115200
*/
parameter RX_ACC_MAX = 50000000 / (115200 * 16);
parameter TX_ACC_MAX = 50000000 / 115200;
parameter RX_ACC_WIDTH = $clog2(RX_ACC_MAX);
parameter TX_ACC_WIDTH = $clog2(TX_ACC_MAX);
reg [RX_ACC_WIDTH - 1:0] rx_acc = 0;
reg [TX_ACC_WIDTH - 1:0] tx_acc = 0;

assign rxclk_en = (rx_acc == 5'd0); //clock enable signal for receiver module, rate = 16*baud rate
assign txclk_en = (tx_acc == 9'd0); //clock enable signal for transmitter module, rate = baud rate


always @(posedge clk_50MHZ) 
begin
    //increment tx_acc at TX_ACC_MAX
	if (tx_acc == TX_ACC_MAX[TX_ACC_WIDTH - 1:0])
		tx_acc <= 0;
	else
		tx_acc <= tx_acc + 9'b1;
end

always @(posedge clk_50MHZ) 
begin
    //increment rx_acc at RX_ACC_MAX
	if (rx_acc == RX_ACC_MAX[RX_ACC_WIDTH - 1:0])
		rx_acc <= 0;
	else
		rx_acc <= rx_acc + 5'b1;
end

endmodule



//-----------------------------------------------------------------------------------------------


module UART_Receiver(input wire rx,
		                 output reg rdy,
		                 input wire rdy_clr,
		                 input wire clk_50MHZ,
		                 input wire clken,
		                 output reg [7:0] data);

initial begin
	rdy = 0; //data not ready
	data = 8'b0; //data  = 00000000
end

parameter STATE_START_BIT	= 2'b00;
parameter STATE_DATA		= 2'b01;
parameter STATE_STOP_BIT	= 2'b10;

reg [1:0] state = STATE_START_BIT;
reg [3:0] counter = 0;
reg [3:0] bitpos = 0;
reg [7:0] draft_reg = 8'b0;

always @(posedge clk_50MHZ) 
begin
	if (rdy_clr)    //if ready flag is cleared
		  rdy <= 0;   //not ready

	if (clken) begin //clock enabled
		case (state)
		  STATE_START_BIT: 
        begin
			     /*
            we will start the counter from the first time we sample a low(0),
            once we have sampled a full bit, we will start collecting data bits 
            (we will go to STATE_DATA )
            */
			    if (!rx || counter != 0) //if sampled rx = low
				  counter <= counter + 4'b1; //add 1 to the counter

			     if (counter == 15)
             begin
				      state <= STATE_DATA;
				      bitpos <= 0;
				      counter <= 0;
				      draft_reg <= 0;
			       end
		    end
		  
		  STATE_DATA: 
        begin
			   counter <= counter + 4'b1; //increment the counter
			   if (counter == 4'h8) //start collecting data if counter = 8 which means we will sample in the middle of the bit
            begin
				      draft_reg[bitpos[2:0]] <= rx; //collect bits in draft_reg register
				      bitpos <= bitpos + 4'b1; // next bit in next position
			       end
			   if (bitpos == 8 && counter == 15) //successfully sampled 8 bits
				      state <= STATE_STOP_BIT;  
		    end
		  STATE_STOP_BIT: 
        begin
              /*if the counter is complete
              or if we are least half way into the stop bit
              & we receive a start bit, we will handle the next start bit
              this inaccuracy may happen because the clk rates may be different
              between sender & receiver.
              */
			     if (counter == 15 || (counter >= 8 && !rx))  
              begin
				        state <= STATE_START_BIT; //next state
				        data <= draft_reg; //move date from draft to parallel data lines
				        rdy <= 1'b1; //flag data as ready
				        counter <= 0; //reset the counter
			        end 
           else
              begin
				        counter <= counter + 4'b1;
			        end
		     end
		     
		  default: 
        begin
			     state <= STATE_START_BIT; //default case is STATE_START_BIT
		    end
		endcase
	end
end

endmodule

//-----------------------------------------------------------------------------------------------

module UART_Transmitter(input wire [7:0] data_in,
		                    input wire tx_start,
		                    input wire clk_50MHZ,
		                    input wire clken,
		                    output reg tx,
		                    output wire tx_busy);

initial begin
	   tx = 1'b1; //for idle state
end

parameter STATE_IDLE	     = 2'b00;
parameter STATE_START_BIT	= 2'b01;
parameter STATE_DATA	     = 2'b10;
parameter STATE_STOP_BIT	 = 2'b11;

reg [7:0] data = 8'h00; //used as a shift register to send parallel received data as serial
reg [2:0] bitpos = 3'h0;
reg [1:0] state = STATE_IDLE; //initial state

always @(posedge clk_50MHZ) begin
	case (state)
	STATE_IDLE: 
  begin
		if (tx_start) //if system raises tx_start flag
      begin 
			 state <= STATE_START_BIT;
			 data <= data_in; //put the parallel data in the shift register
			 bitpos <= 3'h0; 
		  end
	end
	STATE_START_BIT: 
  begin
		if (clken) 
      begin
			 tx <= 1'b0; //tx line set to 0 (start bit)
			 state <= STATE_DATA; //start transmitting data
		  end
	end
	STATE_DATA: 
    begin
		if (clken) begin
			if (bitpos == 3'h7) //if data register is full 
				  state <= STATE_STOP_BIT;
			else
				bitpos <= bitpos + 3'h1; //increment bit position
			tx <= data[bitpos]; //transmit data serially on the line
		  end
	end
	STATE_STOP_BIT: 
  begin
		if (clken) 
      begin
			 tx <= 1'b1; //put stop bit on tx line
			 state <= STATE_IDLE; //return to idle state
		  end
	end
	default: 
    begin
		tx <= 1'b1;
		state <= STATE_IDLE;
	 end
	endcase
end

assign tx_busy = (state != STATE_IDLE); //raise busy flag if not in idle state

endmodule

//----------------------------------------------------------------------------------------------
// UART TOP MODULE
module UART(input wire [7:0] data_in,
	          input wire tx_start,
	          input wire clk_50MHZ,
	          output wire tx,
	          output wire tx_busy,
	          input wire rx,
	          output wire rdy,
	          input wire rdy_clr,
	          output wire [7:0] data_out);

wire rxclk_en, txclk_en;

Baud_Rate_Generator uart_baud(.clk_50MHZ(clk_50MHZ),
			                        .rxclk_en(rxclk_en),
			                        .txclk_en(txclk_en));

UART_Transmitter uart_tx(.data_in(data_in),
		                     .tx_start(tx_start),
		                     .clk_50MHZ(clk_50MHZ),
		                     .clken(txclk_en),
		                     .tx(tx),
		                     .tx_busy(tx_busy));
                         
UART_Receiver uart_rx(.rx(rx),
		                  .rdy(rdy),
		                  .rdy_clr(rdy_clr),
		                  .clk_50MHZ(clk_50MHZ),
		                  .clken(rxclk_en),
		                  .data(data_out));

endmodule