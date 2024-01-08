module dualram(clk_i,rst_i,wr_addr_i,rd_addr_i,wdata_i,rdata_o,wr_en_i,rd_en_i);

parameter WIDTH=16;
parameter DEPTH=256;
parameter ADDR_WIDTH=8;

input clk_i,rst_i;
input [ADDR_WIDTH-1:0] wr_addr_i,rd_addr_i;
input [WIDTH-1:0] wdata_i;
output reg [WIDTH-1:0] rdata_o;
input wr_en_i;
input rd_en_i;

reg [WIDTH-1:0] mem[DEPTH-1:0];
integer i;

always @(posedge clk_i)
 begin
  if (rst_i==1)
    begin
     rdata_o=0;
     for (i=0;i<DEPTH;i=i+1)
       mem[i]=0;
    end
  else
   begin
    if (wr_en_i==1)
      mem[wr_addr_i]=wdata_i;
    if (rd_en_i==1)
     rdata_o=mem[rd_addr_i];
   end
 end

 
endmodule
