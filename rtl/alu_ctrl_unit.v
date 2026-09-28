module alu_ctrl_unit(
    input [6:0] opcode,
    input [6:0] func7,
    input [2:0] func3,
    input [1:0] alu_op,
    output reg [3:0] alu_ctrl
);

always @(*) begin
    alu_ctrl=4'b0000;
    case(alu_op)
    2'b00:alu_ctrl=4'b0000; // ADD for load/store instructions
    2'b01:alu_ctrl=4'b0001; // SUB for compare
    2'b10:begin
        case(opcode)
        7'd51:begin  // R-Type Instructions
            case({func7[5],func3})
            {1'b0,3'b000}:alu_ctrl=4'b0000;  // add (add)
            {1'b1,3'b000}:alu_ctrl=4'b0001;  // subtract (sub)
            {1'b0,3'b001}:alu_ctrl=4'b0101;  // shift left logical (sll)
            {1'b0,3'b010}:alu_ctrl=4'b1001;  // set less than (slt)
            {1'b0,3'b011}:alu_ctrl=4'b1000;  // set less than (unsigned) (sltu)
            {1'b0,3'b100}:alu_ctrl=4'b0100;  // xor (xor)
            {1'b0,3'b101}:alu_ctrl=4'b0110;  // shift right logical (srl)
            {1'b1,3'b101}:alu_ctrl=4'b0111;  // shift right arithmetic (sra)
            {1'b0,3'b110}:alu_ctrl=4'b0011;  // or (or)
            {1'b0,3'b111}:alu_ctrl=4'b0010;  // and (and)
            default:alu_ctrl=4'b0;
            endcase
        end
        7'd19:begin  // I-Type Instructions
            case(func3)
            3'b000:alu_ctrl=4'b0000;  // add (addi)
            3'b001:alu_ctrl=4'b0101;  // shift left logical (slli)
            3'b010:alu_ctrl=4'b1001;  // set less than (slti)
            3'b011:alu_ctrl=4'b1000;  // set less than (unsigned) (sltiu)
            3'b100:alu_ctrl=4'b0100;  // xor (xori)
            3'b101:begin
                if(func7[5]==1'b0)begin
                    alu_ctrl=4'b0110;  // shift right logical (srli)
                end else begin
                    alu_ctrl=4'b0111;  // shift right arithmetic immediate (srai)
                end
            end
            3'b110:alu_ctrl=4'b0011;  // or (ori)
            3'b111:alu_ctrl=4'b0010;  // and (andi)
            default:alu_ctrl=4'b0;
            endcase
        end
        default:alu_ctrl=4'b0000;
        endcase
    end
    endcase
end

endmodule