`include "ffo.v"
module ffo_tb;

parameter WIDTH=8;
parameter DEPTH=16;
parameter PTR_WIDTH=4;

reg clk_i,rst_i,wr_en_i,rd_en_i;
reg [WIDTH-1:0] wdata_i;
 
wire [WIDTH-1:0] rdata_o;
wire full_o,empty_o,wr_error_o,rd_error_o;

integer i;
reg [30*8:1] testname;

fifotest dut(clk_i,rst_i,wdata_i,rdata_o,full_o,empty_o,wr_en_i,rd_en_i,wr_error_o,rd_error_o);

// clock generation
initial
  clk_i=0;
always
  begin
   clk_i=1; #5;
   clk_i=0; #5;
  end

// reset apply,release
initial
  begin
     $value$plusargs("testname=%s",testname);
     rst_i=1;   //apply
     wdata_i=0;
     wr_en_i=0;
     rd_en_i=0;
     #5;
     rst_i=0;   // release
     
     case(testname)
     "test_full" : begin
                      write_fifo(DEPTH);
                   end
     "test_empty" : begin
                      write_fifo(DEPTH);
                      read_fifo(DEPTH);
                   end
     "test_full_error" : begin
                           write_fifo(DEPTH+1);
                         end
     "test_empty_error" :begin
                           write_fifo(DEPTH);
                           read_fifo(DEPTH+1);
                         end
     "test_concurrent_wr_rd" : begin
                               end
     endcase
    
     #300;
     $finish;

  end

task write_fifo(input integer num_write);
begin
 // write
     for (i=0;i<=num_write;i=i+1)
        begin
          @(posedge clk_i);
          wr_en_i=1;
          wdata_i=$random;
        end
     @(posedge clk_i);
     wr_en_i=0;
     wdata_i=0;
end
endtask

task read_fifo(input integer num_read);
begin
// read
     for (i=0;i<=num_read;i=i+1)
        begin
          @(posedge clk_i);
          rd_en_i=1;
        end
     @(posedge clk_i);
     rd_en_i=0;
end
endtask
endmodule

