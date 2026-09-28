module imm_gen(
    input [31:0] inst,
    input [2:0] imm_sel,
    output reg [31:0] imm_out
);

always @(*) begin
    case(imm_sel)
    3'b000:imm_out={{20{inst[31]}},inst[31:20]};                                     // I-Type
    3'b001:imm_out={{20{inst[31]}},inst[31:25],inst[11:7]};                          // S-Type
    3'b010:imm_out={{19{inst[31]}},inst[31],inst[7],inst[30:25],inst[11:8],1'b0};    // B-Type
    3'b011:imm_out={inst[31:12],12'b0};                                              // U-Type
    3'b100:imm_out={{11{inst[31]}},inst[31],inst[19:12],inst[20],inst[30:21],1'b0};  // J-Type
    default:imm_out=32'b0;
    endcase
end

endmodule