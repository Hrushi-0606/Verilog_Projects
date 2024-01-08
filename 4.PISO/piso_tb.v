`include "piso.v"
`include "afifopiso.v"
`include "afifopiso_tb.v"
module piso_tb;

parameter S_FIFO_EMPTY=3'b001;
parameter S_RD_FIFO=3'b010;
parameter S_DRIVE_SERIAL_INTF=3'b100;

reg pclk_i,rst_i,sclk_i;
reg [7:0] data_i;
reg valid_i; 
reg ready_i;

wire ready_o;
wire data_o;
wire valid_o;

integer i;

piso dut(pclk_i,rst_i,sclk_i,
data_i,valid_i,ready_o,
data_o,valid_o,ready_i);


initial       // serial clk shld be 8 times faster than parallel clock
pclk_i=0;
initial
begin
 forever #8 pclk_i=~pclk_i;
end


initial       
sclk_i=0;
initial
begin
 forever #1 sclk_i=~sclk_i;
end

initial
begin
  rst_i=1;
  #20;
  rst_i=0;
  // stimulus:- start driving parallel data into the design
  for (i=0;i<10;i=i+1)
    begin
      @(posedge pclk_i);
      data_i=$random;
      valid_i=1;
      wait (ready_o==1);
    end
  @(posedge pclk_i);
  data_i=0;
  valid_i=0;
  #500;
  $finish;
end

always @(posedge sclk_i)
begin
  if (valid_o==1)
   ready_i=1;
  else
    ready_i=0;
end



endmodule
