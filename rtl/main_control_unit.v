module ctrl_unit(
    input [6:0] opcode,
    output reg regf_w,
    output reg [1:0] alu_op,
    output reg alu_src,
    output reg [2:0] imm_sel,
    output reg mem_w,
    output reg mem_r,
    output reg [1:0] result_src,
    output reg jump,
    output reg branch
);

always @(*) begin
    regf_w=1'b0;
    alu_op=2'b0;
    alu_src=1'b0;
    imm_sel=3'b000;
    mem_w=1'b0;
    mem_r=1'b0;
    result_src=2'b0;
    jump=1'b0;
    branch=1'b0;

    case(opcode)
    7'd51:begin  // R-Type
        regf_w=1'b1;
        alu_op=2'b10;
        alu_src=1'b0;
        result_src=2'b00;
    end

    7'd19:begin  // I-Type
        regf_w=1'b1;
        alu_op=2'b10;
        imm_sel=3'b000;
        alu_src=1'b1;
        result_src=2'b00;
    end

    7'd3:begin  // I-Type Load
        regf_w=1'b1;
        alu_src=1'b1;
        imm_sel=3'b000;
        mem_r=1'b1;
        result_src=2'b01;
        alu_op=2'b00;
    end

    7'd35:begin // S-Type
        mem_w=1'b1;
        alu_op=2'b00;
        alu_src=1'b1;
        imm_sel=3'b001;
    end

    7'd23:begin // U-Type auipc
        regf_w=1'b1;
        alu_src=1'b1;
        alu_op=2'b00;
        imm_sel=3'b011;
        result_src=2'b00;
    end

    7'd55:begin // U-Type lui
        alu_op=2'b00;
        imm_sel=3'b011;
        regf_w=1'b1;
        alu_src=1'b1;
        result_src=2'b11;
    end

    7'd99:begin  // B-Type
        alu_op=2'b01;
        alu_src=1'b0;
        branch=1'b1;
        imm_sel=3'b010;
        result_src=2'b00;
    end

    7'd103:begin // I-Type jalr
        imm_sel=3'b000;
        result_src=2'b10;
        regf_w=1'b1;
        alu_src=1'b1;
        jump=1'b1;
        alu_op=2'b00;
    end

    7'd111:begin  // J-Type jal
        regf_w=1'b1;
        jump=1'b1;
        result_src=2'b10;
        imm_sel=3'b100;
    end

    default:begin  // default case
        regf_w=1'b0;
        alu_op=2'b00;
        alu_src=1'b0;
        imm_sel=3'b000;
        mem_w=1'b0;
        mem_r=1'b0;
        result_src=2'b00;
        jump=1'b0;
        branch=1'b0;
    end
    endcase
end

endmodule