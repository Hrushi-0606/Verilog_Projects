`timescale 1ns/1ps
module dualram_tb;

parameter WIDTH=16;
parameter DEPTH=256;
parameter ADDR_WIDTH=8;

reg clk_i,rst_i;
reg [ADDR_WIDTH-1:0] wr_addr_i,rd_addr_i;
reg [WIDTH-1:0] wdata_i;
wire [WIDTH-1:0] rdata_o;
reg wr_en_i;
reg rd_en_i;

integer i,j;

dualram dut(clk_i,rst_i,wr_addr_i,rd_addr_i,wdata_i,rdata_o,wr_en_i,rd_en_i);

initial
 begin
   clk_i=0;
   forever #5 clk_i=~clk_i;
 end

initial
 begin
   rst_i=1;
   wr_en_i=0;
   rd_en_i=0;
   wr_addr_i=0;
   rd_addr_i=0;
   wdata_i=0;
   #50;
   rst_i=0;
 end

initial
  begin
    write();
    read();
    #500;
    $finish;
  end
 
task write();
 begin
  for (i=0;i<DEPTH;i=i+1)
    begin
      @(posedge clk_i);
      wr_addr_i=i;
      wdata_i=$random;
      wr_en_i=1;
    end
  @(posedge clk_i);
  wr_addr_i=0;
  wdata_i=0;
  wr_en_i=0;
 end
endtask

task read();
 begin
  for (j=0;j<DEPTH;j=j+1)
    begin
      @(posedge clk_i);
      rd_addr_i=j;
      rd_en_i=1;
    end
  @(posedge clk_i);
  rd_addr_i=0;
  wr_en_i=0;
 end
endtask


endmodule
