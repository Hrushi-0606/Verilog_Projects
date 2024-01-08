`include "afifopiso.v"
module afifopiso_tb;

parameter WIDTH=8;
parameter DEPTH=16;
parameter PTR_WIDTH=4;
parameter WR_CLK_I=10;
parameter RD_CLK_I=20;

reg wr_clk_i,rd_clk_i,rst_i,wr_en_i,rd_en_i;
reg [WIDTH-1:0] wdata_i;
 
wire [WIDTH-1:0] rdata_o;
wire full_o,empty_o,wr_error_o,rd_error_o;

integer i;


afifopiso dut(wr_clk_i,rd_clk_i,rst_i,wdata_i,rdata_o,full_o,empty_o,wr_en_i,rd_en_i,wr_error_o,rd_error_o);

// clock generation for write
initial
  wr_clk_i=0;
always
  begin
   wr_clk_i=1; #(WR_CLK_I/2.0);
   wr_clk_i=0; #(WR_CLK_I/2.0);
  end

// clock generation for read
initial
  rd_clk_i=0;
always
  begin
   rd_clk_i=1; #(RD_CLK_I/2.0);
   rd_clk_i=0; #(RD_CLK_I/2.0);
  end

// reset apply,release
initial
  begin
     
     rst_i=1;   //apply
     wdata_i=0;
     wr_en_i=0;
     rd_en_i=0;
     #5;
     rst_i=0;   // release
     
     write_fifo(DEPTH);
     read_fifo(DEPTH);
    
     #200;
     $finish;

  end

task write_fifo(input integer num_write);
begin
 // write
     for (i=0;i<=num_write;i=i+1)
        begin
          @(posedge wr_clk_i);
          wr_en_i=1;
          wdata_i=$random;
        end
     @(posedge wr_clk_i);
     wr_en_i=0;
     wdata_i=0;
end
endtask

task read_fifo(input integer num_read);
begin
// read
     for (i=0;i<=num_read;i=i+1)
        begin
          @(posedge rd_clk_i);
          rd_en_i=1;
        end
     @(posedge rd_clk_i);
     rd_en_i=0;
end
endtask

endmodule

