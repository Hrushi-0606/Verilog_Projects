`timescale 1ns/1ps
`include "afifopiso.v"
`include "afifopiso_tb.v"

module piso(pclk_i,rst_i,sclk_i,
data_i,valid_i,ready_o,
data_o,valid_o,ready_i);

parameter S_FIFO_EMPTY=3'b001;
parameter S_RD_FIFO=3'b010;
parameter S_DRIVE_SERIAL_INTF=3'b100;

input pclk_i,rst_i,sclk_i;
input [7:0] data_i;
input valid_i;
input ready_i;

output reg ready_o;
output reg data_o;
output reg valid_o;

reg [7:0] wr_data_t;
reg wr_en_t;
wire full_t;
wire [7:0] rd_data_t;
reg rd_en_t;

wire empty_t;
wire wr_error_t;
wire rd_error_t;

integer count;

reg [2:0] state,next_state;

// BLOCK 1:-glue circuit

always @(posedge pclk_i)
begin
 if (rst_i==1)
    begin
     ready_o=0;
     data_o=0;
     valid_o=0;
     wr_data_t=0;
     wr_en_t=0;
     rd_en_t=0;
     state=S_FIFO_EMPTY;
     next_state=S_FIFO_EMPTY;
    end
 else
   begin
    if (valid_i==1 && full_t==0)
      begin
      wr_en_t=1;
      wr_data_t=data_i;
      ready_o=1;
      end
    else
      begin
       wr_en_t=0;
       ready_o=0;
      end
   end
end

// BLOCK 2:- glue ckt to asynchronous fifo

afifopiso dut(.wr_clk_i(pclk_i),.rd_clk_i(sclk_i),.rst_i(rst_i),.wdata_i(wr_data_t),.rdata_o(rd_data_t),.full_o(full_t),.empty_o(empty_t),.wr_en_i(wr_en_t),.rd_en_i(rd_en_t),.wr_error_o(wr_error_t),.rd_error_o(rd_error_t));


// BLOCK 3:-

always @(posedge sclk_i)
begin
  if (rst_i==1)
   begin
     case (state)
       S_FIFO_EMPTY: begin
                       if (empty_t==0)
                          begin
                            next_state=S_RD_FIFO;
                            rd_en_t=1;
                          end
                     end
       S_RD_FIFO:begin
                   rd_en_t=0;
                   next_state=S_DRIVE_SERIAL_INTF;
                   count=0;
                 end
       S_DRIVE_SERIAL_INTF:begin
                             data_o=rd_data_t[count];
                             valid_o=1;
                             if (ready_i==1)
                               count=count+1;  
                             if (count==8)
                               begin
                                 count=0;
                                 valid_o=0;
                                 if (empty_t==1)
                                    next_state=S_FIFO_EMPTY;
                                 else 
                                   begin
                                    next_state=S_RD_FIFO;
                                    rd_en_t=1;
                                   end
                               end                 
                           end
     endcase     
   end
end


always @(next_state)
begin
  state=next_state;
end

endmodule
