`include "fifoaconc.v"
module fifoaconc_tb;

parameter WIDTH=8;
parameter DEPTH=16;
parameter PTR_WIDTH=4;
parameter WR_CLK_I=10;
parameter RD_CLK_I=20;
parameter MAX_WR_DELAY=10;
parameter MAX_RD_DELAY=10;
parameter NUM_WR_TIMES=400;
parameter NUM_RD_TIMES=200;

reg wr_clk_i,rd_clk_i,rst_i,wr_en_i,rd_en_i;
reg [WIDTH-1:0] wdata_i;
 
wire [WIDTH-1:0] rdata_o;
wire full_o,empty_o,wr_error_o,rd_error_o;

integer seed;
integer i;
integer j;
integer p;
integer q;
integer wr_delay;
integer rd_delay;
reg [30*8:1] testname;

fifoaconc dut(wr_clk_i,rd_clk_i,rst_i,wdata_i,rdata_o,full_o,empty_o,wr_en_i,rd_en_i,wr_error_o,rd_error_o);

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
     $value$plusargs("testname=%s",testname);
     rst_i=1;   //apply
     wdata_i=0;
     wr_en_i=0;
     rd_en_i=0;
     seed=1212;
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
                                 fork
                                   begin // NUM_WR_TIMES writes happens with random delay between them. Delay being 1 to MAX_WR_DELAY
                                     for (p=0;p<NUM_WR_TIMES;p=p+1)    // assume it happens for 500 times in whole operation, now all 500 cant happen at the same so we introduce delay after that delay maybe write will happen....
                                        begin
                                          write_fifo(1);     // write one data into the FIFO
                                          // wr_delay=$urandom_range(1,MAX_WR_DELAY);
                                          wr_delay=1+$random(seed)%MAX_WR_DELAY; // added 1 bcz we want to start from 1 to max_wr_delay
                                          repeat (wr_delay) @(posedge wr_clk_i); // 
                                        end
                                   end
                                   begin
                                     for (q=0;q<NUM_RD_TIMES;q=q+1)  //NUM_RD_TIMES read happens with random delay between them. Delay being 1 to MAX_WR_DELAY  
                                        begin
                                          read_fifo(1);     // read one data from the FIFO
                                          // rd_delay=$urandom_range(1,MAX_RD_DELAY);
                                          rd_delay=1+$random(seed)%MAX_RD_DELAY;
                                          repeat (rd_delay) @(posedge rd_clk_i); // 
                                        end
                                   end
                                 join
                               end
     endcase
    
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
     for (j=0;j<=num_read;j=j+1)
        begin
          @(posedge rd_clk_i);
          rd_en_i=1;
        end
     @(posedge rd_clk_i);
     rd_en_i=0;
end
endtask
endmodule


