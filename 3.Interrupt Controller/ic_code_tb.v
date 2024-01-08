`include "ic_code.v"
module ic_code_tb;
parameter NUM_INTR=16;
parameter S_NO_INTR=3'b001;
parameter S_INTR_ACTIVE=3'b010;
parameter S_INTR_GIVEN_WAIT_FOR_SERVICE=3'b100;

reg pclk_i,prst_i,pwrite_i,penable_i,intr_serviced_i;
reg [7:0] pwdata_i;
reg [7:0] paddr_i;
reg [15:0] intr_active_i;

reg [3:0] prio_arr[15:0];  // so total 16 random and unique numbers between 0 to 15
reg[8*40:1] testname;

wire [7:0] prdata_o;
wire pready_o;
wire perror_o;
wire [3:0] intr_to_service_o; 
wire intr_valid_o;

integer i,p;
integer seed;

wire [2:0] state,next_state;
wire first_match_f;
wire [3:0] current_high_priority;
wire [3:0] intr_with_high_priority;

ic_code dut(
// processor
pclk_i,prst_i,paddr_i,pwdata_i,prdata_o,pwrite_i,penable_i,pready_o,perror_o,intr_valid_o,intr_to_service_o,intr_serviced_i,
// peripherals
intr_active_i
);
// this instantation can also be done by using ic dut(.*);


// clk generation
initial
pclk_i=0;
always
begin
 pclk_i=1; #5;
 pclk_i=0; #5;
end

initial
begin
  $value$plusargs("testname=%s",testname);
  $value$plusargs("seed=%d",seed);
  prst_i=1;
  rst_design_inputs();
  #20;
  prst_i=0;
  fill_prio_arr();
// stimulus are
// 1) programming the registers
// 2) generationg the interrupts

// 1) programming the registers-->writing the registers 
// In this we taking taking 0th number will have 0 priority, 1st will have 1 priority and 15 will have 15 priority....
if (testname=="test_random_priority") 
begin
  for (p=0;p<NUM_INTR;p=p+1)
      begin
       $display("index=%0d,number=%0d",p,prio_arr[p]);
      end
end

for (i=0;i<NUM_INTR;i=i+1)
  begin
  if (testname=="test_lowest_peri_lowest_priority") write_reg(i,i);   // 0-->0,1-->1 ,2-->2 first i will go to the addr of the task write_reg and second i will go the data 
  if (testname== "test_lowest_peri_highest_priority") write_reg(i,NUM_INTR-1-i);   // 0-->15, 1-->14, 15-->0
  if (testname=="test_random_priority")  // random priorties
    begin    
      write_reg(i,prio_arr[i]);
    end
  end
// 2)  generationg the interrupts
intr_active_i=$random;
#500;    // taking time to answer all questions
intr_active_i=$random;
#500;
intr_active_i=$random;
#500;
$finish;

end


task write_reg(input reg [3:0] addr,input reg [3:0] data);
begin
 @(posedge pclk_i);
 paddr_i=addr;  // address of the register
 pwdata_i=data; //priority value
 pwrite_i=1;
 penable_i=1;
 wait (pready_o==1)
 @(posedge pclk_i);
 paddr_i=0;
 pwrite_i=0;
 pwdata_i=0;
 penable_i=0;
end
endtask

initial
begin
  forever
     begin
       @(posedge pclk_i);
       if (intr_valid_o==1)
         begin
           #30;   // time given to processor to respond to the interrupt and solve the issue
           intr_active_i[intr_to_service_o]=0;  // dropping the interrupt since it has been answered(serviced) the interrupt
           intr_serviced_i=1; // processor will say to tell the interrupt controlleer that processor has answered 
           @(posedge pclk_i);
           intr_serviced_i=0;
         end
     end
end

task rst_design_inputs();
begin 
  penable_i=0;
  pwdata_i=0;
  pwrite_i=0;
  paddr_i=0;
  intr_serviced_i=0;
  intr_active_i=0;
end
endtask

task fill_prio_arr();
integer p,q,r;
integer random_num;
reg unique_num_f;
begin
  for (p=0;p<NUM_INTR;)
begin
      // random_num=$urandom_range(0,15);
      random_num=$random(seed)%16;
      unique_num_f=1;
      for (q=0;q<p;q=q+1)
         begin
           if (random_num==prio_arr[q])
             begin
               // exit for loop
               unique_num_f=0;  // number already exists
               q=p;
             end
         end
      if (unique_num_f==1)  // after going over for loop, we figured that number generated is unique
          begin
            prio_arr[p]=random_num;
            p=p+1;
          end
end
   // by this stage, we have filled the array with 16 unique random numbers between 0 and 15   
end

endtask


endmodule

