module d_latch (input d,input en,output reg q);      

   // This always block is "always" triggered whenever en/rstn/d changes  
   // If reset is asserted, then the output will be zero   
   // Else as long as enable is high, output q follows input d  
  
   always @ (en /*or rstn*/ or d)  
      /*if (!rstn)  
         q <= 0;  
      else  */
         if (en)  
            q <= d;  
endmodule
 
module RisingEdge_DFlipFlop(D,clk,Q);
input D; // Data input 
input clk; // clock input 
output reg Q; // output Q 
always @(posedge clk) 
begin
 Q <= D; 
end 
endmodule

module tristate_buffer(input_x, enable, output_x);

input input_x;

input enable;

output output_x;

assign output_x = enable? input_x : 'bz;

endmodule
module buffer(input_x, output_x);

input input_x;
output output_x;

assign output_x = input_x;

endmodule

module P(en,wval,outset,  val,rval,outread);
input en,wval,outset;
output val,rval,outread;
wire wire1,val,wire2,outread;
//RisingEdge_DFlipFlop f1(.D(wval),.clk(clk),.Q(wire1));
d_latch l1( .d(wval),.en(en)/*,.rstn(1)*/,.q(wire1));
tristate_buffer tb1(.input_x(wire1), .enable(outset), .output_x(val));
buffer b1(.output_x(wire2),.input_x(val));
//RisingEdge_DFlipFlop f2(.D(wire2),.clk(clk),.Q(rval));
d_latch l2( .d(wire2),.en(en)/*,.rstn(1)*/,.q(rval));

endmodule
module GPIOpins(en,wval,outset,  val,rval,outread);
input en;
input[7:0] wval,outset;
output[7:0] rval,val,outread;
assign outread = outset;

P p0(.en(en),.wval(wval[0]),.outset(outset[0]),  .val(val[0]),.rval(rval[0]),.outread(outread[0]));
P p1(.en(en),.wval(wval[1]),.outset(outset[1]),  .val(val[1]),.rval(rval[1]),.outread(outread[1]));
P p2(.en(en),.wval(wval[2]),.outset(outset[2]),  .val(val[2]),.rval(rval[2]),.outread(outread[2]));
P p3(.en(en),.wval(wval[3]),.outset(outset[3]),  .val(val[3]),.rval(rval[3]),.outread(outread[3]));
P p4(.en(en),.wval(wval[4]),.outset(outset[4]),  .val(val[4]),.rval(rval[4]),.outread(outread[4]));
P p5(.en(en),.wval(wval[5]),.outset(outset[5]),  .val(val[5]),.rval(rval[5]),.outread(outread[5]));
P p6(.en(en),.wval(wval[6]),.outset(outset[6]),  .val(val[6]),.rval(rval[6]),.outread(outread[6]));
P p7(.en(en),.wval(wval[7]),.outset(outset[7]),  .val(val[7]),.rval(rval[7]),.outread(outread[7]));
endmodule
module pinsInterfaceModule(writeData,writeDirection,readData,readDirection, select,writeEnable,inputData,outputData);
  input [7:0] readData,readDirection,inputData;
  input select,writeEnable;
  output reg [7:0] writeData,writeDirection,outputData;
  always @(readData,readDirection,select,writeEnable,inputData) begin
    case (select)//reading
      1'b0: begin//data
        outputData <= readData;
      end
      1'b1: begin//direction
        outputData <= readDirection;
      end
    endcase
    case ({writeEnable,select})//writing
      2'b00: begin//no writing
        //nop
      end
      2'b01: begin//no writing
        //nop
      end
      2'b10: begin//writing data
        writeData <= inputData;
      end
      2'b11: begin//writing direction
        writeDirection <= inputData;
      end
    endcase
  end
  
endmodule

module GPIO(writeData,wen,sel,  readData,pins);
input [7:0] writeData;
input wen,sel;

output [7:0] pins;
output [7:0] readData;

wire [7:0] wvalWire, outsetWire,valWire,rvalWire,outreadWire;



GPIOpins pinsModule(.en(1'b1),.val(pins),/*from here*/ /*set data*/.wval(wvalWire),/*set direction*/.outset(outsetWire),  /*read data*/.rval(rvalWire),/*read direction*/.outread(outreadWire));
pinsInterfaceModule pi(.writeData(wvalWire),.writeDirection(outsetWire),.readData(rvalWire),.readDirection(outreadWire), .select(sel),.writeEnable(wen),.inputData(writeData),.outputData(readData));

endmodule

module APBGPIOInterface(PCLK,PRESETn,PSEL,PENABLE,PWRITE,PADDR,PWDATA,PRDATA1,PREADY,writeData,wen,sel,readData);
input wire PWRITE,PRESETn,PCLK,PSEL,PENABLE;//bottom

//left
input wire [7:0] PWDATA,PADDR;
output reg[7:0] PRDATA1;
output reg PREADY;

//right
output reg [7:0] writeData;
output reg wen,sel;
input wire[7:0] readData;

always @(posedge PCLK,PRESETn) begin
    if (PRESETn == 0) begin//reset disabled
        if(PSEL == 1)begin//if device selected
        PREADY = 1'b1;
        if(PENABLE == 1'b1)begin //if enabled
            if(PWRITE == 1'b1)begin//if enabled and write enabled
                wen =1'b1;//enable write
                if(PADDR == 8'b00000000)begin//if data reg selected
                    sel = 1'b0;
                end else if(PADDR == 8'b00000001)begin//if direction reg selected
                    sel = 1'b1;
                end else begin

                end
                writeData = PWDATA;

            end else begin // if enabled and read enabled
                wen = 1'b0;//disable write
                if(PADDR == 8'b00000000)begin//if data reg selected
                    sel = 1'b0;
                end else if(PADDR == 8'b00000001)begin//if direction reg selected
                    sel = 1'b1;
                end
                PRDATA1 = readData;

            end
        end else begin//if disabled

        end
    end else begin//if device is not selected
        
    end
    end else begin//reset enabled
        wen = 1'b1;
        sel = 1'b1;
        #1
        writeData = 8'b00000000;
        #1
        sel = 1'b0;
        writeData = 8'b00000000;
        wen = 1'b0;
    end
    
    
end
endmodule
module clockGen(clk);
output reg clk;
initial
	clk = 0;
always
	#10 clk = ~clk;

endmodule

module GPIOAPB(/*PCLK*/PRESETn,PSEL,PENABLE,PWRITE,PADDR,PWDATA,PRDATA1,PREADY,pins);

input wire PWRITE,PRESETn,/*PCLK,*/PSEL,PENABLE;//buttom

output wire [7:0] pins;//right

//left
input wire [7:0] PWDATA,PADDR;
output wire [7:0] PRDATA1; //wireeeeeeeeeee
output wire PREADY;
//internal wires
wire [0:7] writeData,readData;
wire wen,sel;
//test
wire PCLK;

//instantiation
GPIO g(.writeData(writeData),.wen(wen),.sel(sel),.readData(readData),.pins(pins));
APBGPIOInterface a(.PCLK(PCLK),.PRESETn(PRESETn),.PSEL(Psel),.PENABLE(PENABLE),.PWRITE(PWRITE),.PADDR(PADDR),.PWDATA(PWDATA),.PRDATA1(PRDATA1),.PREADY(PREADY),.writeData(writeData),.wen(wen),.sel(sel),.readData(readData));
clockGen c(clk);
//GPIO g(.writeData(writeData),.wen(wen),.sel(sel),  .readData(readData),.pins(pins));

//slave1 s(.PCLK(),PRESETn(),.PSEL(),.PENABLE(),.PWRITE(),.PADDR(),.PWDATA(),.PRDATA1(),.PREADY())
endmodule

module GPIOTestbenchOut(pins,readData);
//inputs reg
reg [7:0] writeData;
reg wen,sel;
output wire [7:0] pins;
output wire [7:0] readData;
GPIO g(.writeData(writeData),.wen(wen),.sel(sel),  .readData(readData),.pins(pins));


initial begin
    //writing and reading data
    wen = 1; //enable writing
    sel = 1; //select direction control register
    #100
    writeData = 8'b11111111; //setting all pins as outputs
    #100
    
    
    sel = 0; //selecting data register
    writeData = 8'b00000000; //setting all ouput pins as output low (test case 1)
    #100
    writeData = 8'b10101010; //test case 2
    #100
    writeData = 8'b01010101; // test case 3
    #100
    writeData = 8'b11111111; // test case 4
    #100
    wen = 0; //disable writing
    #100
    //trying to write to both registers while disable writing to test  
    writeData = 8'b00000000;
    sel = 0;
    #100
    writeData = 8'b00000000;
    sel = 1;
    //reading data


end

endmodule

module GPIOTestbenchIn(pins,readData);
//inputs reg
reg [7:0] writeData;
reg wen,sel;
output wire [7:0] pins;
output wire [7:0] readData;
reg isInput;
GPIO g(.writeData(writeData),.wen(wen),.sel(sel),  .readData(readData),.pins(pins));
reg [7:0] setPins;
tristate_buffer tsb0(.input_x(setPins[0]), .enable(isInput), .output_x(pins[0]));
tristate_buffer tsb1(.input_x(setPins[1]), .enable(isInput), .output_x(pins[1]));
tristate_buffer tsb2(.input_x(setPins[2]), .enable(isInput), .output_x(pins[2]));
tristate_buffer tsb3(.input_x(setPins[3]), .enable(isInput), .output_x(pins[3]));
tristate_buffer tsb4(.input_x(setPins[4]), .enable(isInput), .output_x(pins[4]));
tristate_buffer tsb5(.input_x(setPins[5]), .enable(isInput), .output_x(pins[5]));
tristate_buffer tsb6(.input_x(setPins[6]), .enable(isInput), .output_x(pins[6]));
tristate_buffer tsb7(.input_x(setPins[7]), .enable(isInput), .output_x(pins[7]));
initial begin
    //writing and reading data
    isInput = 1;
    wen = 1; //enable writing
    sel = 1; //select direction control register
    #100
    writeData = 8'b00000000; //setting all pins as outputs
    #100
    
    
    sel = 0; //selecting data register
    writeData = 8'b00000000; //setting all ouput pins as output low (test case 1)
    #100
    writeData = 8'b10101010; //test case 2
    #100
    setPins =   8'b10101010;
    writeData = 8'b01010101; // test case 3
    #100
    setPins =   8'b00000000;
    writeData = 8'b11111111; // test case 4
    #100
    wen = 0; //disable writing
    #100
    //trying to write to both registers while disable writing to test  
    writeData = 8'b00000000;
    sel = 0;
    #100
    writeData = 8'b00000000;
    sel = 1;
    //reading data


end

endmodule

