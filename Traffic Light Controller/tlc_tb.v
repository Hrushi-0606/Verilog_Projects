`include "tlc.v"
module tlc_tb;

reg x,clk,rst;
wire [1:0] hwy,cntry;

tlc dut(clk,rst,x,hwy,cntry);

initial
  clk=0;
always
 begin  
  clk=1; #5;
  clk=0; #5; 
 end

initial
 begin
  state=S0;
  next_state=S0;
  hwy=GREEN;
  cntry=RED;
 end 

initial
 begin
   rst=1;
   #50;
   rst=0;x=1; 
   #200;
   rst=0;x=0;
   #100;
   rst=0;x=1;
   #200;
   $finish;
 end

endmodule
