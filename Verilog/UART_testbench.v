`include "UART.v"
`timescale 1ns/1ns
module uart_tx_test();

reg [7:0] data = 0;
reg clk = 0;
reg enable = 0;

wire tx_busy;
wire rdy;
wire [7:0] rxdata;

wire loopback;
reg rdy_clr = 0;

UART test_uart(.data_in(data),
	       .tx_start(enable),
	       .clk_50MHZ(clk),
	       .tx(loopback),
	       .tx_busy(tx_busy),
	       .rx(loopback),
	       .rdy(rdy),
	       .rdy_clr(rdy_clr),
	       .data_out(rxdata));

initial begin
	$dumpfile("UART.vcd");
	$dumpvars(0, uart_tx_test);
	enable <= 1'b1;
	#20 enable <= 1'b0;
end

always begin
	#10 clk = ~clk;
end

always @(posedge rdy) begin
	#20 rdy_clr <= 1;
	#20 rdy_clr <= 0;
	if (rxdata != data) begin
		$finish;
	end else begin
		if (rxdata == 8'hff) begin
			$finish;
		end
		data <= data + 1'b1;
		enable <= 1'b1;
		#20 enable <= 1'b0;
	end
end

endmodule

