module regf(
    input clk,
    input [4:0] rs1,rs2,rd,
    input [31:0] write_data,
    input write_en,
    output [31:0] rd1,rd2
);

reg [31:0] register_file [31:0];
integer i;

always @(posedge clk) begin
    if((write_en==1) && (rd!=5'b0)) begin
        register_file[rd]=write_data;
    end
end

initial begin
    for(i=0; i<32; i=i+1)
        register_file[i] = 32'h0;
end

assign rd1 = (rs1==5'b0) ? 32'b0:
    ((write_en && (rd == rs1)) ? write_data : register_file[rs1]);
assign rd2 = (rs2==5'b0) ? 32'b0:
    ((write_en && (rd == rs2)) ? write_data : register_file[rs2]);

endmodule