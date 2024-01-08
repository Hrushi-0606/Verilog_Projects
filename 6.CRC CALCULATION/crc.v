module crc;
reg [7:0] data;
reg [2:0] poly;
reg [1:0] crc;
reg [2:0] remainder;
integer i;

initial
 begin
   poly=3'b101;
   data=8'b11010100;
   remainder = data[7:5];
   for (i=7;i>1;i=i-1)
     begin
       $display("remainder=%b",remainder);
       remainder=remainder^poly;
       if (i==2)
          begin
            crc=remainder;
          end
       data=data<<1;
       if (remainder[2:0]==3'b000)
         begin
           i=i-2;
           remainder={data[5:3]};
           data=data<<2;
         end
       else if(remainder[2:1]==2'b00)
          begin
            i=i-1;
            remainder={remainder[0],data[5:4]};
            data=data<<1;
          end
       else if (remainder[2]==1'b0)
           begin
             remainder={remainder[1:0],data[5]};
           end
     end
    $display("CRC=%b",crc);
 end


endmodule
