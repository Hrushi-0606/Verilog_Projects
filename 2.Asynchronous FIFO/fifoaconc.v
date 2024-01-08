`timescale 1ns/1ps
module fifoaconc(wr_clk_i,rd_clk_i,rst_i,wdata_i,rdata_o,full_o,empty_o,wr_en_i,rd_en_i,wr_error_o,rd_error_o);

// PARAMETER DECLARATION
parameter WIDTH=8;
parameter DEPTH=16;
parameter PTR_WIDTH=4;

// INPUTS
input wr_clk_i,rd_clk_i,rst_i,wr_en_i,rd_en_i;
input [WIDTH-1:0] wdata_i;

// OUTPUTS 
output reg [WIDTH-1:0] rdata_o;
output reg full_o,empty_o,wr_error_o,rd_error_o;

// WRITE AND READ POINTER (INTERNAL TO DESIGN)
reg [PTR_WIDTH-1:0] wr_ptr;
reg [PTR_WIDTH-1:0] rd_ptr;  
reg [PTR_WIDTH-1:0] wr_ptr_gray;
reg [PTR_WIDTH-1:0] rd_ptr_gray; 

reg [PTR_WIDTH-1:0] wr_ptr_gray_rd_clk; 
reg [PTR_WIDTH-1:0] rd_ptr_gray_wr_clk; 

reg [PTR_WIDTH-1:0] wr_ptr_rd_clk;
reg [PTR_WIDTH-1:0] rd_ptr_wr_clk;

 // WRITE AND READ TOGGLES (SCALARS)   
reg wr_toggle_f,rd_toggle_f;   
reg wr_toggle_f_rd_clk,rd_toggle_f_wr_clk;     

// DECLARATION OF MEMEORY
reg [WIDTH-1:0] mem [DEPTH-1:0]; 

integer i;
//PROCESSES IN FIFO I.E WRITE AND READ

// write

always @(posedge wr_clk_i)
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
   wr_ptr_gray=0;
   rd_ptr_gray=0;
   wr_ptr_rd_clk=0;
   rd_ptr_wr_clk=0;
   wr_ptr_gray_rd_clk=0;
   rd_ptr_gray_wr_clk=0;  
   wr_toggle_f=0;
   rd_toggle_f=0;
   wr_toggle_f_rd_clk=0;
   rd_toggle_f_wr_clk=0;
   // we cant give mem=0 
   for (i=0;i<DEPTH;i=i+1)
     begin
       mem[i]=1;
     end
   end

 else   // when rst_i is not applied i.e either write or read will happen
wr_error_o=0;
  
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
              wr_ptr_gray={wr_ptr[3],wr_ptr[3:1]^wr_ptr[2:0]};
            end
        end
 
end
end


// read

always @(posedge rd_clk_i)
begin
 if (rst_i!=1)   // go into this block only when rst is not applied
   begin
     rd_error_o=0;  

    
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
                   rd_ptr_gray={rd_ptr[3],rd_ptr[3:1]^rd_ptr[2:0]}; // rd_ptr-->MSB bit, remaining bits will be xored among themselve to get the gray code...Basically its just the binary to gray code
                 
              
            end
        end 

 
   end
end


// LOGIC FOR FULL & EMPTY CONDITION

always @(*)
begin
 empty_o=0;
 full_o=0;
   // full
   if (wr_ptr_gray==rd_ptr_gray_wr_clk)
      begin
        if (wr_toggle_f != rd_toggle_f_wr_clk)
           full_o=1;
      end
   // empty
   if (wr_ptr_gray_rd_clk==rd_ptr_gray)
      begin
        if (wr_toggle_f_rd_clk == rd_toggle_f)
           empty_o=1;
      end
end

// Synchronization of read and write clocks

always @(posedge rd_clk_i)
begin 
  wr_ptr_gray_rd_clk<=wr_ptr_gray;
  wr_toggle_f_rd_clk<=wr_toggle_f;
end

always @(posedge wr_clk_i)
begin 
  rd_ptr_gray_wr_clk<=rd_ptr_gray;
  rd_toggle_f_wr_clk<=rd_toggle_f;
end

endmodule

