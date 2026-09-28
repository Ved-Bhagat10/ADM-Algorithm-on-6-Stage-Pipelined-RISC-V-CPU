module alu (
    input [31:0] a,b,
    input [3:0] alu_ctrl,
    output reg [31:0] result,
    output zero,
    output reg carry,
    output reg overflow
);

always @(*) begin
    carry=1'b0;
    overflow=1'b0;
    case(alu_ctrl)
    4'b0000:begin // add
        {carry,result}=a+b;
        overflow=(a[31]==b[31])&&(a[31]!=result[31]);
    end
    4'b0001:begin // sub
        {carry,result}=a-b;
        overflow=(a[31]!=b[31])&&(a[31]!=result[31]);
    end
    4'b0010:result=a&b; // and
    4'b0011:result=a|b; // or
    4'b0100:result=a^b;// xor
    4'b0101:result=a<<b[4:0]; // shift left logical
    4'b0110:result=a>>b[4:0]; // shift right logical
    4'b0111:result=($signed(a)>>>b[4:0]); // shift right arithmetic
    4'b1000:result=(a<b)?32'd1:32'd0; // set if less than (unsigned)
    4'b1001:result=(($signed(a))<($signed(b)))?32'd1:32'd0; // set less than
    default:result=32'b0;
    endcase
end

assign zero=(result==32'b0);

endmodule