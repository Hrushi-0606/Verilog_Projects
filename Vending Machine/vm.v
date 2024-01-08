`timescale 1ns/1ps
module vm(clk,rst,in,out);

parameter S0=2'b00;
parameter S1=2'b01;
parameter S2=2'b10;

input clk,rst;
input [1:0] in;
output reg out;

reg [1:0] state,next_state;

always @(state or in)
 begin
  case(state)
     S0: begin
           if (in==2'b00)
              begin
                next_state=S0;
                out=0;
              end
           else if(in==2'b01)
              begin
                next_state=S1;
                out=0;
              end
           else if (in==2'b10)
              begin
                next_state=S2;
                out=0;
              end
         end
     S1: begin
           if (in==2'b00)
              begin
                next_state=S0;
                out=0;
              end
           else if(in==2'b01)
              begin
                next_state=S2;
                out=0;
              end
           else if (in==2'b10)
              begin
                next_state=S0;
                out=1;
              end
         end
     S2: begin
           if (in==2'b00)
              begin
                next_state=S0;
                out=0;
              end
           else if(in==2'b01)
              begin
                next_state=S0;
                out=1;
              end
           else if (in==2'b10) 
              begin
                next_state=S0;
                out=1;
              end
         end
  endcase
 end

always @(posedge clk)
 begin
   if (rst==1)
     begin
      state=0;
     end
   else
      state=next_state;
 end
endmodule
