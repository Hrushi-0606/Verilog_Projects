`timescale 1ns/1ps
module spi_control(
// APB
pclk_i,prst_i,paddr_i,pwdata_i,prdata_o,pwrite_i,pready_o,penable_i,
// SPI
sclk_ref_i,sclk_o,miso,mosi,cs
);

parameter S_IDLE=5'b00001;
parameter S_ADDR=5'b00010;
parameter S_IDLE_BW_ADDR_DATA=5'b00100;
parameter S_DATA=5'b01000;
parameter S_IDLE_WITH_TX_PENDING=5'b10000;
parameter MAX_NUM_TXS=8;

input pclk_i,prst_i,pwrite_i,penable_i;
input [7:0]paddr_i;
input [7:0]pwdata_i;
output reg [7:0]prdata_o;
output reg pready_o;
input sclk_ref_i;
output reg sclk_o;
input miso;
output reg mosi;
output reg [3:0] cs;

reg [4:0] state,next_state;
reg sclk_gated_f;

// declaring register and memories
reg [7:0] addr_regA[MAX_NUM_TXS-1:0];  // 'h0 to MAX_NUM_TX-1
reg [7:0] data_regA[MAX_NUM_TXS-1:0];  // 'h10 to 'h10+NUM_TX-1
reg [7:0] ctrl_reg;               // 'h20

integer i;
reg [2:0] cur_tx_idx;
reg [3:0] num_txs_pending;
integer count;
reg [7:0] addr_to_drive;
reg [7:0] data_to_drive;
reg [7:0] data_collect;    // data coming from slave during reads
 
// there will be 2 processes
// 1. programming the registers
// 2.doing the spi tx.

// programming the registers

always @(posedge pclk_i)
begin
  if (prst_i==1)
      begin
        // make all reg variables as 0.
        prdata_o=0;
        pready_o=0;
        ctrl_reg=0;
        sclk_gated_f=1;
        for (i=0;i<MAX_NUM_TXS;i=i+1)
          begin
           addr_regA[i]=0;
           data_regA[i]=0;
          end
        state=S_IDLE;
        next_state=S_IDLE;
        sclk_o=1;
        mosi=1;
        data_collect=0;
        cs=4'b1;
        cur_tx_idx=0;
        num_txs_pending=0;
        addr_to_drive=0;
        data_to_drive=0;
        count=0;
      end
  else
      begin
         if (penable_i==1)
            begin
               pready_o=1;
               // write registers 
               if (pwrite_i==1)
                  begin
                    if (paddr_i>=8'h0 && paddr_i<=8'h7)
                      begin
                          addr_regA[paddr_i]=pwdata_i;
                      end
                    if (paddr_i>=8'h10 && paddr_i<=8'h17)
                      begin
                          data_regA[paddr_i-8'h10]=pwdata_i;
                      end
                    if (paddr_i==8'h20)
                      begin
                           ctrl_reg[3:0]=pwdata_i[3:0];  // Since upper four bits are read only
                      end
                  end
                // read registers 
                else
                   begin
                    if (paddr_i>=8'h0 && paddr_i<=8'h7)
                      begin
                          prdata_o=addr_regA[paddr_i];
                      end
                    if (paddr_i>=8'h10 && paddr_i<=8'h17)
                      begin
                          prdata_o=data_regA[paddr_i-8'h10];
                      end
                    if (paddr_i==8'h20)
                      begin
                           prdata_o=ctrl_reg;
                      end
                  end 
            end
          else
            begin
              pready_o=0;
            end
      end
end

// SPI TX.

always @(posedge sclk_ref_i)
 begin
   if (prst_i==0)
     begin
        case (state)
           S_IDLE: begin
                      mosi=1;
                      addr_to_drive=0;
                      data_to_drive=0;
                      count=0;
                      sclk_gated_f=1;    // clk is not running
                      if (ctrl_reg[0])
                        begin
                          cur_tx_idx=ctrl_reg[6:4];
                          num_txs_pending=ctrl_reg[3:1]+1;
                          next_state=S_ADDR;
                          count=0;
                          addr_to_drive=addr_regA[cur_tx_idx];
                          data_to_drive=data_regA[cur_tx_idx];
                        end
                   end
           S_ADDR: begin
                     sclk_gated_f=0;
                     mosi=addr_to_drive[count];
                     count=count+1;
                     if (count==8)
                        begin
                           next_state=S_IDLE_BW_ADDR_DATA;
                           count=0;
                        end
                   end
           S_IDLE_BW_ADDR_DATA: begin
                                  sclk_gated_f=1;
                                  count=count+1;
                                  mosi=1;
                                  if (count==4)  // here we want to keep the delay between two wdata, so we have assumed here it to be 4
                                     begin
                                       next_state=S_DATA;
                                       count=0;
                                     end
                                end
           S_DATA: begin
                      sclk_gated_f=0;
                      if (addr_to_drive[7]==1)   // write
                         begin
                           // master drives data to slave on mosi
                           mosi=data_to_drive[count];
                           count=count+1;
                         end
                      if (addr_to_drive[7]==0)   // read
                         begin
                          // slave drives data to master on miso
                          data_to_drive[count]=miso;
                          count=count+1;
                         end
                      if (count==8)
                         begin
                           num_txs_pending=num_txs_pending-1;  // still these many txs are remaining 
                           count=0;
                           ctrl_reg[6:4]=ctrl_reg[6:4]+1;
                           cur_tx_idx=cur_tx_idx+1;
                           if (num_txs_pending==0)
                             begin
                               next_state=S_IDLE;
                               ctrl_reg[0]=0;
                               ctrl_reg[3:1]=0;
                             end
                           else
                             begin
                                next_state=S_IDLE_WITH_TX_PENDING;
                             end
                         end
                   end
            S_IDLE_WITH_TX_PENDING: begin
                                    sclk_gated_f=1;
                                    count=count+1;
                                    mosi=1;
                                       if (count==4)
                                         begin
                                           next_state=S_DATA;
                                           addr_to_drive=addr_regA[cur_tx_idx];
                                           data_to_drive=data_regA[cur_tx_idx];
                                           count=0;
                                         end
                                    end        
        endcase
     end
 end

always @(sclk_ref_i)
  begin
    if (sclk_gated_f==1)
       sclk_o=1;
    else 
       sclk_o=sclk_ref_i;
  end

always @(next_state)
  state=next_state;
endmodule
