`timescale 1ns/1ns
module UART_APB_interface(
    input PCLK,          
    input PRESETn,       
    input [31:0] PADDR,    
    input [31:0] PWDATA, 
    input PSELx,
    input PWRITE,
    input PENABLE,
    output [31:0] PRDATA, 
    output reg PREADY = 0,
    input [7:0] data_out, 
    input rdy,
    input tx_start, 
    output [7:0] data_in,  
    output reg rdy_clr = 0
);
localparam holdDuration = 15;


assign data_in = PWDATA;
assign PRDATA [7:0] = data_out;

always @(posedge PCLK, posedge PRESETn) begin
    if(PSELx && PRESETn) begin
        rdy_clr = 1;
        #holdDuration
        rdy_clr = 0;
    end
    else if(PSELx && PENABLE) begin
        case(PWRITE) 
            1: begin 
                PREADY = tx_start;
            end
            0: begin 
                PREADY = rdy;
            end
        endcase
    end
    else begin
        PREADY = 0;
    end
end


endmodule