`timescale 1ns/1ps
module fifotest(clk_i,rst_i,wdata_i,rdata_o,full_o,empty_o,wr_en_i,rd_en_i,wr_error_o,rd_error_o);

// PARAMETER DECLARATION
parameter WIDTH=8;
parameter DEPTH=16;
parameter PTR_WIDTH=4;

// INPUTS
input clk_i,rst_i,wr_en_i,rd_en_i;
input [WIDTH-1:0] wdata_i;

// OUTPUTS 
output reg [WIDTH-1:0] rdata_o;
output reg full_o,empty_o,wr_error_o,rd_error_o;

// WRITE AND READ POINTER (INTERNAL TO DESIGN)
reg [PTR_WIDTH-1:0] wr_ptr;
reg [PTR_WIDTH-1:0] rd_ptr;   
 // WRITE AND READ TOGGLES (SCALARS)   
reg wr_toggle_f,rd_toggle_f;        

// DECLARATION OF MEMEORY
reg [WIDTH-1:0] mem [DEPTH-1:0]; 

integer i;
//PROCESSES IN FIFO I.E WRITE AND READ

always @(posedge clk_i)
begin
 if (rst_i==1)
   begin
   // All reg values assign to zero
   rdata_o=0;
   full_o=0;
   empty_o=1;
   wr_error_o=0;
   rd_error_o=0;
   wr_ptr=0;
   rd_ptr=0;
   wr_toggle_f=0;
   rd_toggle_f=0;
   // we cant give mem=0 
   for (i=0;i<DEPTH;i=i+1)
     begin
       mem[i]=1;
     end
   end

 else   // when rst_i is not applied i.e either write or read will happen
   wr_error_o=0;
   rd_error_o=0;
   begin
    //WRITE
      
     if (wr_en_i==1)
        begin
          if(full_o==1)
            begin
              wr_error_o=1;
            end
          else
            begin
              // store the data into the memory
              mem[wr_ptr]=wdata_i;
              
              // increment the wr_ptr
              if (wr_ptr == DEPTH-1)
                 
              wr_toggle_f = ~(wr_toggle_f);   // when its goes from (DEPTH)16--> 0 the wr_toggle shld happen it shld go from 0 to 1 and so on...
                 
              wr_ptr<=wr_ptr+1;
            end
        end
    
     // READ
       
       if (rd_en_i==1)
        begin
          if(empty_o==1)
            begin
              rd_error_o=1;
            end
          else
            begin
              // get data from the memory
              rdata_o=mem[rd_ptr];
              
              // increment the rd_ptr
              if (rd_ptr == DEPTH-1)
                 
                   rd_toggle_f = ~(rd_toggle_f);   // when its goes from (DEPTH)16--> 0 the rd_toggle shld happen it shld go from 0 to 1 and so on...
                   rd_ptr<=rd_ptr+1;
                 
              
            end
        end 

 
end
end

// LOGIC FOR FULL AND EMPTY GENERATION

always @(*)
begin
 empty_o=0;
 full_o=0;
   if (wr_ptr==rd_ptr)
      begin
        if (wr_toggle_f == rd_toggle_f)
           empty_o=1;
        if (wr_toggle_f != rd_toggle_f)
           full_o=1;
      end
end
endmodule

