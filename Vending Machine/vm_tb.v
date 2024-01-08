`include "vm.v"
module vm_tb;

parameter S0=2'b00;
parameter S1=2'b01;
parameter S2=2'b10;

reg clk,rst;
reg [1:0] in;
wire out;

vm dut(clk,rst,in,out);

initial
 begin
  clk=0;
  forever #5 clk=~clk;
 end

initial
 begin
      rst=1;
      #10;
      rst=0;
      in=2'b00;
   #5 in=2'b01;
   #5 in=2'b10;
   #5 in=2'b10;
   #5 in=2'b00;
   #5 in=2'b10;
   #5 in=2'b01;
   #5 in=2'b00;
   #5 in=2'b10;
   #5 in=2'b00;
   #5 in=2'b10;
   #10;
   $finish;
 end

endmodule
