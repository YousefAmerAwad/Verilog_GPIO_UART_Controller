module master_apb(
    input  pclk,
    input penable_master,
    input  pwrite,
    input transfer,
    input Reset,
    input [1:0] Psel,
    input [4:0]  write_paddr,read_paddr,
    input [31:0] write_data,   
    input pready,
    input [31:0] prdata,
    output reg pwrite_slave , penable,
    output reg [31:0] pwdata,
    output reg[4:0]paddr,
    output reg PSEL1,PSEL2,
    output reg [31:0] apb_read_data
);

localparam IDLE = 2'b00, SETUP = 2'b01, Access = 2'b10 ;
reg [2:0] CurrentState=IDLE, NextState=IDLE;


always @(Psel) begin
    case (Psel)
        1 : begin
          PSEL1 <= 1;
          PSEL2 <= 0;
        end 
        2 : begin
          PSEL1 <= 0;
          PSEL2 <= 1;
        end
        default: begin
            PSEL1 <= 0;
            PSEL2 <= 0;
        end 
    endcase
end
// Psel1 , Psel2 

//assign {PSEL1,PSEL2} = ((CurrentState != IDLE) ? (Psel == 1 ? {1'b0,1'b1} : {1'b1,1'b0}) : 2'd0);


always @(CurrentState,transfer,pready) begin   
            pwrite_slave <= pwrite; 
            case (CurrentState)
                IDLE: 
                    begin
                        penable = 0;
                        if (transfer) begin
                            NextState <= SETUP;
                        end                       
                    end
                SETUP:
                    begin
                        penable = 0;
                        // if Master called Write Bus will send Address of Write else will send read Address
                        // write data in setup
                        if (pwrite) begin
                            paddr <= write_paddr;
                            pwdata <= write_data;

                        end
                        else begin
                            paddr <= read_paddr;
                        end
                        if (transfer) begin
                            NextState <= Access;
                        end
                    end
                Access:
                    begin
                        if (PSEL1 || PSEL2)
                            penable = 1;
                        if (transfer)
                        begin
                            /*if (PADDR == slave1Addr) {
                                PSEL1 = 1'b1;
                                PSEL2 = 1'b0;
                            }
                            else {
                                slave2Addr = PADDR;
                                PSEL2 = 1'b1;
                                PSEL1 = 1'b0;
                            }*/
                            if (pready) 
                            begin
                                if (pwrite)
                                    NextState <= SETUP;
                                else
                                begin
                                    NextState <= SETUP;
                                    apb_read_data = prdata;
                                end
                            end
                      
                        end
                        else
                            NextState = IDLE;
                    end
            endcase
end

always @(posedge pclk or posedge Reset) begin
    if (Reset) begin
        CurrentState <= IDLE;
    end
    else begin
        CurrentState <= NextState;
    end
end
endmodule
//*******************************************************************//



