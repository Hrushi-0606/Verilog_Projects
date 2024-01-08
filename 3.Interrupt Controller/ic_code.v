`timescale 1ns/1ps
module ic_code(
// processor
pclk_i,prst_i,paddr_i,pwdata_i,prdata_o,pwrite_i,penable_i,pready_o,perror_o,intr_valid_o,intr_to_service_o,intr_serviced_i,
// peripherals
intr_active_i
);

parameter NUM_INTR=16;   // NO OF PERIPHERALS
parameter S_NO_INTR=3'b001;
parameter S_INTR_ACTIVE=3'b010;
parameter S_INTR_GIVEN_WAIT_FOR_SERVICE=3'b100;

// INPUTS
input pclk_i,prst_i,pwrite_i,penable_i,intr_serviced_i;
input [7:0] pwdata_i;
input [7:0] paddr_i;
input [15:0] intr_active_i;

// OUTPUTS
output reg [7:0] prdata_o;
output reg pready_o;
output reg perror_o;
output reg intr_valid_o;
output reg [3:0] intr_to_service_o;     // this is related to parameter NUM_INR=16=2^4...that only is represented over here

integer i;
reg [2:0] state,next_state;
reg first_match_f;
reg [3:0] current_high_priority;
reg [3:0] intr_with_high_priority;

// Register declaration
reg [7:0] priority_regA[NUM_INTR-1:0];

// Register programming
always @(posedge pclk_i)
begin
  if (prst_i==1)
      begin
        // make all reg variables as 0.
        prdata_o=0;
        pready_o=0;
        perror_o=0;
        intr_to_service_o=0;
        intr_valid_o=0;
        first_match_f=1;
        current_high_priority=0;
        intr_with_high_priority=0;
        for (i=0;i<NUM_INTR;i=i+1)
          begin
           priority_regA[i]=0;
          end
        state=S_NO_INTR;
        next_state=S_NO_INTR;
      end
  else
      begin
         if (penable_i==1)
            begin
               pready_o=1; 
               if (pwrite_i==1)
                  begin
                    priority_regA[paddr_i]=pwdata_i;
                  end 
                else
                    begin
                      prdata_o=priority_regA[paddr_i];
                    end
            end
         else
            begin
              pready_o=0;
            end
      end
end

// Interrupt Handling

always @(posedge pclk_i)
begin
  if (prst_i !=1)
    begin
       case (state)
          S_NO_INTR: begin
                        if (intr_active_i !=0)
                          begin 
                          next_state=S_INTR_ACTIVE;
                          first_match_f=1;
                          end
                     end
          S_INTR_ACTIVE: begin
                         // GET THE HIGHEST PRIORITY INTERRUPT AMONG ALL THE ACTIVE INTERRUPT AND GIVE IT TO PROCESSOR & THEN JUMP TO NEXT STATE
                         for (i=0;i<NUM_INTR;i=i+1)
                           begin
                             if (intr_active_i[i]==1)
                               begin
                                  if (first_match_f==1)
                                     begin
                                        current_high_priority=priority_regA[i];
                                        intr_with_high_priority=i;
                                        first_match_f=0;
                                     end
                                   else 
                                      begin
                                         if (current_high_priority<priority_regA[i])
                                            begin
                                              current_high_priority=priority_regA[i];
                                              intr_with_high_priority=i;
                                            end
                                      end
                               end
                              
                           end
                         // at the end of this, we will get current_high_priority and intr_with_high_priority

                         intr_to_service_o=intr_with_high_priority;       // Here, we are givng the intr_with_high_priority to the processsor,so that it can do the needful 
                         intr_valid_o=1;
                         next_state=S_INTR_GIVEN_WAIT_FOR_SERVICE;
                         end
          S_INTR_GIVEN_WAIT_FOR_SERVICE: begin
                                           if (intr_serviced_i==1)     // this will tell that processor has answered the interrupt
                                              begin
                                              intr_to_service_o=0;   // so that interrupt is dropped now move to next interrupt
                                              intr_valid_o=0;
                                              intr_with_high_priority=0;
                                              current_high_priority=0;    
                                                 if (intr_active_i !=0)   // this will check are there any further interrupts 
                                                    begin
                                                       next_state=S_INTR_ACTIVE;  // if interrupt arev present then go t S_INTR_ACTIVE state
                                                       first_match_f=1;
                                                    end
                                                 else
                                                    begin
                                                      next_state=S_NO_INTR;   // if no further interrupt, go to S_NO_INTR state
                                                    end
                                              end
                                         end
       endcase
    end
end

always @(next_state)
 state=next_state;

endmodule

