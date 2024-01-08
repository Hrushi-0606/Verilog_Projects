`timescale 1ns/1ps
module tlc(clk,rst,x,hwy,cntry);

parameter TRUE=1'b1;
parameter FALSE=1'b0;

parameter RED=2'd0;
parameter YELLOW=2'd1;
parameter GREEN=2'd2;
//                              HWY        CNTRY
parameter S0=3'd0;    //       GREEN         RED
parameter S1=3'd1;    //       YELLOW        RED 
parameter S2=3'd2;    //         RED         RED
parameter S3=3'd3;    //       RED          GREEN
parameter S4=3'd4;    //        RED         YELLOW

parameter Y2R_DELAY=3;
parameter R2G_DELAY=2;

input x,clk,rst;
output reg [1:0] hwy,cntry;
reg [2:0] state,next_state;

always @(posedge clk)
  state=next_state;
  always @(state)
    begin
     case(state)
       S0: begin
            hwy=GREEN;
            cntry=RED;
           end
       S1: begin
             hwy=YELLOW;
             cntry=RED;
           end
       S2: begin
             hwy=RED;
             cntry=RED;
           end
       S3: begin
             hwy=RED;
             cntry=GREEN;
           end
       S4: begin
             hwy=RED;
             cntry=YELLOW;
           end
     endcase
    end

always @(state,rst,x)
 begin
  if (rst==1)
    state=S0;   
  else
    case(state)
      S0: if (x==1)
             next_state=S1;
          else 
             next_state=S0;
      S1: begin
            repeat (Y2R_DELAY) @(posedge clk)
            next_state=S2;
          end
      S2: begin
            repeat (R2G_DELAY) @(posedge clk)
            next_state=S3;
          end
      S3: if (x==1)
            next_state=S3;
          else
            next_state=S4;
      S4: begin
            repeat (Y2R_DELAY) @(posedge clk)
            next_state=S0;
          end
      default: next_state=S0;
    endcase    
 end


endmodule
