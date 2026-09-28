module cpu (
    input clk,
    input reset,
    input [31:0] adc_sample,
    output reg [31:0] cpu_output,
    (* mark_debug = "true" *) output reg dac_strobe,
    (* mark_debug = "true" *) input ip_buf_wr
);

    // ============================================================
    // 1. DECLARATIONS
    // ============================================================

    (* mark_debug = "true" *) wire [31:0] pc;
    wire [31:0] pc_next, pc_plus_four;
    wire [31:0] instruction;
    reg [31:0] inst_mem [0:255];
    reg [31:0] ip_buffer [0:255];

    // IF/ID
    reg [31:0] if_id_pc;
    (* mark_debug = "true" *) reg [31:0] if_id_inst;
    reg [31:0] if_id_pc_plus_four;

    wire [6:0] opcode, func7;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] func3;
    wire regf_w, alu_src, mem_w, mem_r, jump, branch;
    wire [1:0] alu_op, result_src;
    wire [2:0] imm_sel;
    wire [31:0] imm_out;
    wire [31:0] rd1, rd2, write_data;
    wire [3:0] alu_ctrl;

    // ID/EX1
    reg [31:0] id_ex1_rd1, id_ex1_rd2;
    reg [31:0] id_ex1_imm_out;
    reg [31:0] id_ex1_pc, id_ex1_pc_plus_four;
    reg [6:0] id_ex1_opcode;
    reg [2:0] id_ex1_func3;
    (* mark_debug = "true" *) reg [4:0] id_ex1_rd;
    reg [3:0] id_ex1_alu_ctrl;
    reg id_ex1_regf_w;
    reg id_ex1_mem_w;
    (* mark_debug = "true" *) reg id_ex1_mem_r;
    reg id_ex1_alu_src, id_ex1_branch, id_ex1_jump;
    reg [1:0] id_ex1_result_src;
    reg [4:0] id_ex1_rs1, id_ex1_rs2;
    reg id_ex1_jalr;
    reg id_ex1_is_jump;

    // EX1 stage
    wire [31:0] alu_in1, alu_in2, alu_result;
    wire zero, carry, overflow;

    // EX1/EX2
    reg [31:0] ex1_ex2_alu_result;
    reg [31:0] ex1_ex2_opa;
    reg [31:0] ex1_ex2_opb;
    reg [31:0] ex1_ex2_pc;
    reg [31:0] ex1_ex2_imm_out;
    reg [31:0] ex1_ex2_pc_plus_four;
    (* mark_debug = "true" *) reg [4:0]  ex1_ex2_rd;
    reg ex1_ex2_regf_w, ex1_ex2_mem_w;
    (* mark_debug = "true" *) reg ex1_ex2_mem_r;
    reg [1:0] ex1_ex2_result_src;
    reg ex1_ex2_branch;
    reg [2:0] ex1_ex2_func3;
    reg ex1_ex2_is_jump;
    reg ex1_ex2_jalr;

    // EX2 stage
    wire branch_taken;
    wire [31:0] branch_target, jump_target, jalr_target;
    wire ex2_zero;

    // EX2/MEM
    (* mark_debug = "true" *) reg [31:0] ex2_mem_alu_result;
    (* mark_debug = "true" *) reg [31:0] ex2_mem_rd2;
    reg [31:0] ex2_mem_pc_plus_four;
    reg [31:0] ex2_mem_imm_out;
    reg [4:0] ex2_mem_rd;
    reg ex2_mem_regf_w;
    (* mark_debug = "true" *) reg ex2_mem_mem_w;
    (* mark_debug = "true" *) reg ex2_mem_mem_r;
    reg [1:0] ex2_mem_result_src;
    (* mark_debug = "true" *) wire [31:0] mem_data;
    wire [31:0] ex2_mem_forward_data;

    // MEM/WB
    reg [31:0] mem_wb_mem_data;
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_pc_plus_four;
    reg [31:0] mem_wb_imm_out;
    reg [4:0] mem_wb_rd;
    reg mem_wb_regf_w;
    reg [1:0] mem_wb_result_src;

    // Hazard
    (* mark_debug = "true" *) wire load_use_hazard;
    wire flush;
    reg [1:0] forward_a_ex;
    reg [1:0] forward_b_ex;
    wire [31:0] forward_data_a;
    wire [31:0] forward_data_b;
    wire [31:0] pc_next_final;
    (* mark_debug = "true" *) wire adc_stall;

    integer j, x;

    // ============================================================
    // 2. INITIAL INSTRUCTION MEMORY (same as before)
    // ============================================================

    initial begin
        for(j = 0; j < 256; j = j + 1) inst_mem[j] = 32'h00000013;

inst_mem[  0] = 32'h00000093;  // addi x1,  x0, 0          # input pointer  (set to real base externally)
inst_mem[  1] = 32'h00000113;  // addi x2,  x0, 0          # output pointer (set to real base externally)
inst_mem[  2] = 32'h00100713;  // addi x14, x0, 1          # MIN_STEP = 2 (1 stalls: step+step>>1 is a fixed point at 1 -- never grows)
inst_mem[  3] = 32'h01000813;  // addi x16, x0, 16         # MAX_STEP = 16          (tune as needed)
inst_mem[  4] = 32'h7FF00993;  // addi x19, x0, 2047       # OUT_MAX build step 1/3
inst_mem[  5] = 32'h00199993;  // slli x19, x19, 1         # OUT_MAX build step 2/3  -> 4094
inst_mem[  6] = 32'h00198993;  // addi x19, x19, 1         # OUT_MAX build step 3/3  -> 4095 (12-bit ADC range)
inst_mem[  7] = 32'h00001237;  // lui  x4, 0x1        # x4 = 0x00001000 = 4096
inst_mem[  8] = 32'h80020213;  // addi x4, x4, -2048  # x4 = 2048
inst_mem[  9] = 32'h00000313;  // addi x6,  x0, 0          # prev_error = 0
inst_mem[ 10] = 32'h000702B3;  // add  x5,  x14, x0        # step seeded to MIN_STEP (was 0 -- bug: 0 x1.5 stays 0 forever)
inst_mem[ 11] = 32'h0000A403;  // lw   x8, 0(x1)
inst_mem[ 12] = 32'h404404B3;  // sub  x9, x8, x4          # error = sample - integrator
inst_mem[ 13] = 32'h0004A533;  // slt  x10, x9, x0         # sign(error)
inst_mem[ 14] = 32'h000325B3;  // slt  x11, x6, x0         # sign(prev_error)
inst_mem[ 15] = 32'h00B547B3;  // xor  x15, x10, x11       # nonzero -> sign reversal
inst_mem[ 16] = 32'h00079863;  // bne  x15, x0, DECREASE
inst_mem[ 17] = 32'h0012D793;  // srli x15, x5, 1
inst_mem[ 18] = 32'h00F282B3;  // add x5, x5, x15                   # step = step + step>>1   (x1.5, exact)
inst_mem[ 19] = 32'h0080006F;  // jal  x0, CLAMP_STEP
inst_mem[ 20] = 32'h0012D293;  // srli x5, x5, 1           # step = step>>1          (x0.5, exact)
inst_mem[ 21] = 32'h00E2A7B3;  // slt  x15, x5, x14
inst_mem[ 22] = 32'h00079863;  // bne  x15, x0, SET_MIN_STEP
inst_mem[ 23] = 32'h005827B3;  // slt  x15, x16, x5
inst_mem[ 24] = 32'h00079863;  // bne  x15, x0, SET_MAX_STEP
inst_mem[ 25] = 32'h0100006F;  // jal  x0, APPLY
inst_mem[ 26] = 32'h000702B3;  // add  x5, x14, x0
inst_mem[ 27] = 32'h0080006F;  // jal  x0, APPLY
inst_mem[ 28] = 32'h000802B3;  // add  x5, x16, x0
inst_mem[ 29] = 32'h02048A63;  // beq  x9, x0, STORE       # error == 0 -> integrator unchanged
inst_mem[ 30] = 32'h00050663;  // beq  x10, x0, UPDATE_POS
inst_mem[ 31] = 32'h40520233;  // sub  x4, x4, x5
inst_mem[ 32] = 32'h0080006F;  // jal  x0, CLAMP_OUTPUT
inst_mem[ 33] = 32'h00520233;  // add  x4, x4, x5
inst_mem[ 34] = 32'h0049A7B3;  // slt  x15, x19, x4        # OUT_MAX < integrator ?
inst_mem[ 35] = 32'h00079863;  // bne  x15, x0, SET_MAX_OUT
inst_mem[ 36] = 32'h000227B3;  // slt  x15, x4, x0         # integrator < 0 ?
inst_mem[ 37] = 32'h00079863;  // bne  x15, x0, SET_MIN_OUT
inst_mem[ 38] = 32'h0100006F;  // jal  x0, STORE
inst_mem[ 39] = 32'h00098233;  // add  x4, x19, x0
inst_mem[ 40] = 32'h0080006F;  // jal  x0, STORE
inst_mem[ 41] = 32'h00000213;  // addi x4, x0, 0
inst_mem[ 42] = 32'h00412023;  // sw   x4, 0(x2)
inst_mem[ 43] = 32'h00048333;  // add  x6, x9, x0          # FIX: prev_error = current error (was writing to x7, dead)
inst_mem[ 44] = 32'h00408093;  // addi x1, x1, 4
inst_mem[ 45] = 32'h00410113;  // addi x2, x2, 4
inst_mem[ 46] = 32'hF75FF06F;  // jal  x0, LOOP

    end

    initial begin
        for (x = 0; x < 256; x = x + 1) ip_buffer[x] = 32'b0;
    end

    // ============================================================
    // 3. IF STAGE
    // ============================================================

    assign pc_plus_four = pc + 32'd4;
    assign instruction = inst_mem[pc[9:2]];
    assign pc_next_final = (load_use_hazard || adc_stall) ? pc : pc_next;

    pc pc_unit (
        .clk(clk),
        .reset(reset),
        .next_pc(pc_next_final),
        .pc(pc)
    );

    // ============================================================
    // 4. IF/ID REGISTER
    // ============================================================

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_pc <= 32'b0;
            if_id_inst <= 32'h00000013;
            if_id_pc_plus_four <= 32'b0;
        end else if (flush) begin
            if_id_pc <= 32'b0;
            if_id_inst <= 32'h00000013;
            if_id_pc_plus_four <= 32'b0;
        end else if (load_use_hazard || adc_stall) begin
            if_id_pc <= if_id_pc;
            if_id_inst <= if_id_inst;
            if_id_pc_plus_four <= if_id_pc_plus_four;
        end else begin
            if_id_pc <= pc;
            if_id_inst <= instruction;
            if_id_pc_plus_four <= pc_plus_four;
        end
    end

    // ============================================================
    // 5. ID STAGE
    // ============================================================

    assign opcode = if_id_inst[6:0];
    assign rd = if_id_inst[11:7];
    assign func3 = if_id_inst[14:12];
    assign rs1 = if_id_inst[19:15];
    assign rs2 = if_id_inst[24:20];
    assign func7 = if_id_inst[31:25];

    ctrl_unit cu_unit (
        .opcode(opcode),
        .regf_w(regf_w),
        .alu_op(alu_op),
        .alu_src(alu_src),
        .imm_sel(imm_sel),
        .mem_w(mem_w),
        .mem_r(mem_r),
        .result_src(result_src),
        .jump(jump),
        .branch(branch)
    );

    imm_gen imm_gen_unit (
        .inst(if_id_inst),
        .imm_sel(imm_sel),
        .imm_out(imm_out)
    );

    regf regf_unit (
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(mem_wb_rd),
        .write_data(write_data),
        .write_en(mem_wb_regf_w),
        .rd1(rd1),
        .rd2(rd2)
    );

    alu_ctrl_unit alu_ctrl_unit_mod (
        .opcode(opcode),
        .func7(func7),
        .func3(func3),
        .alu_op(alu_op),
        .alu_ctrl(alu_ctrl)
    );

    // ============================================================
    // 6. ID/EX1 REGISTER
    // ============================================================

   always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            id_ex1_rd1 <= 32'b0;
            id_ex1_rd2 <= 32'b0;
            id_ex1_imm_out <= 32'b0;
            id_ex1_pc <= 32'b0;
            id_ex1_pc_plus_four <= 32'b0;
            id_ex1_opcode <= 7'b0;
            id_ex1_func3 <= 3'b0;
            id_ex1_rd <= 5'b0;
            id_ex1_alu_ctrl <= 4'b0;
            id_ex1_regf_w <= 1'b0;
            id_ex1_mem_w <= 1'b0;
            id_ex1_mem_r <= 1'b0;
            id_ex1_alu_src <= 1'b0;
            id_ex1_branch <= 1'b0;
            id_ex1_jump <= 1'b0;
            id_ex1_result_src <= 2'b00;
            id_ex1_rs1 <= 5'b0;
            id_ex1_rs2 <= 5'b0;
            id_ex1_jalr <= 1'b0;
            id_ex1_is_jump <= 1'b0;
        end else if (load_use_hazard) begin
            // insert bubble
            id_ex1_rd1 <= 32'b0;
            id_ex1_rd2 <= 32'b0;
            id_ex1_imm_out <= 32'b0;
            id_ex1_pc <= 32'b0;
            id_ex1_pc_plus_four <= 32'b0;
            id_ex1_opcode <= 7'b0;
            id_ex1_func3 <= 3'b0;
            id_ex1_rd <= 5'b0;
            id_ex1_alu_ctrl <= 4'b0;
            id_ex1_regf_w <= 1'b0;
            id_ex1_mem_w <= 1'b0;
            id_ex1_mem_r <= 1'b0;
            id_ex1_alu_src <= 1'b0;
            id_ex1_branch <= 1'b0;
            id_ex1_jump <= 1'b0;
            id_ex1_result_src <= 2'b00;
            id_ex1_rs1 <= 5'b0;
            id_ex1_rs2 <= 5'b0;
            id_ex1_jalr <= 1'b0;
            id_ex1_is_jump <= 1'b0;
        end else if (adc_stall) begin
            // FREEZE: hold whatever instruction is currently here
            id_ex1_rd1 <= id_ex1_rd1;
            id_ex1_rd2 <= id_ex1_rd2;
            id_ex1_imm_out <= id_ex1_imm_out;
            id_ex1_pc <= id_ex1_pc;
            id_ex1_pc_plus_four <= id_ex1_pc_plus_four;
            id_ex1_opcode <= id_ex1_opcode;
            id_ex1_func3 <= id_ex1_func3;
            id_ex1_rd <= id_ex1_rd;
            id_ex1_alu_ctrl <= id_ex1_alu_ctrl;
            id_ex1_regf_w <= id_ex1_regf_w;
            id_ex1_mem_w <= id_ex1_mem_w;
            id_ex1_mem_r <= id_ex1_mem_r;
            id_ex1_alu_src <= id_ex1_alu_src;
            id_ex1_branch <= id_ex1_branch;
            id_ex1_jump <= id_ex1_jump;
            id_ex1_result_src <= id_ex1_result_src;
            id_ex1_rs1 <= id_ex1_rs1;
            id_ex1_rs2 <= id_ex1_rs2;
            id_ex1_jalr <= id_ex1_jalr;
            id_ex1_is_jump <= id_ex1_is_jump;
        end else begin
            id_ex1_rd1 <= rd1;
            id_ex1_rd2 <= rd2;
            id_ex1_imm_out <= imm_out;
            id_ex1_pc <= if_id_pc;
            id_ex1_pc_plus_four <= if_id_pc_plus_four;
            id_ex1_opcode <= opcode;
            id_ex1_func3 <= func3;
            id_ex1_rd <= rd;
            id_ex1_alu_ctrl <= alu_ctrl;
            id_ex1_regf_w <= regf_w;
            id_ex1_mem_w <= mem_w;
            id_ex1_mem_r <= mem_r;
            id_ex1_alu_src <= alu_src;
            id_ex1_branch <= branch;
            id_ex1_jump <= jump;
            id_ex1_result_src <= result_src;
            id_ex1_rs1 <= rs1;
            id_ex1_rs2 <= rs2;
            id_ex1_jalr <= (opcode == 7'd103);
            id_ex1_is_jump <= jump;
        end
    end
    
    // ============================================================
    // 7. EX1 STAGE - ALU
    // ============================================================

    assign alu_in1 = (id_ex1_opcode == 7'd23) ? id_ex1_pc : forward_data_a;
    assign alu_in2 = id_ex1_alu_src ? id_ex1_imm_out : forward_data_b;

    alu alu_unit (
        .a(alu_in1),
        .b(alu_in2),
        .alu_ctrl(id_ex1_alu_ctrl),
        .result(alu_result),
        .zero(zero),
        .carry(carry),
        .overflow(overflow)
    );

    // ============================================================
    // 8. EX1/EX2 REGISTER
    // ============================================================

    always @(posedge clk or posedge reset) begin
        if (reset || flush) begin
            ex1_ex2_alu_result <= 32'b0;
            ex1_ex2_opa <= 32'b0;
            ex1_ex2_opb <= 32'b0;
            ex1_ex2_pc <= 32'b0;
            ex1_ex2_imm_out <= 32'b0;
            ex1_ex2_pc_plus_four <= 32'b0;
            ex1_ex2_rd <= 5'b0;
            ex1_ex2_regf_w <= 1'b0;
            ex1_ex2_mem_w <= 1'b0;
            ex1_ex2_mem_r <= 1'b0;
            ex1_ex2_result_src <= 2'b00;
            ex1_ex2_branch <= 1'b0;
            ex1_ex2_func3 <= 3'b0;
            ex1_ex2_is_jump <= 1'b0;
            ex1_ex2_jalr <= 1'b0;
        end else begin
            ex1_ex2_alu_result <= alu_result;
            ex1_ex2_opa <= forward_data_a;
            ex1_ex2_opb <= forward_data_b;
            ex1_ex2_pc <= id_ex1_pc;
            ex1_ex2_imm_out <= id_ex1_imm_out;
            ex1_ex2_pc_plus_four <= id_ex1_pc_plus_four;
            ex1_ex2_rd <= id_ex1_rd;
            ex1_ex2_regf_w <= id_ex1_regf_w;
            ex1_ex2_mem_w <= id_ex1_mem_w;
            ex1_ex2_mem_r <= id_ex1_mem_r;
            ex1_ex2_result_src <= id_ex1_result_src;
            ex1_ex2_branch <= id_ex1_branch;
            ex1_ex2_func3 <= id_ex1_func3;
            ex1_ex2_is_jump <= id_ex1_is_jump;
            ex1_ex2_jalr <= id_ex1_jalr;
        end
    end

    // ============================================================
    // 9. EX2 STAGE - Branch Decision
    // ============================================================

    assign ex2_zero = (ex1_ex2_alu_result == 32'b0);

    assign branch_taken =
        ex1_ex2_branch && (
            (ex1_ex2_func3 == 3'b000 &&  ex2_zero) ||
            (ex1_ex2_func3 == 3'b001 && !ex2_zero) ||
            (ex1_ex2_func3 == 3'b100 && ($signed(ex1_ex2_opa) <  $signed(ex1_ex2_opb))) ||
            (ex1_ex2_func3 == 3'b101 && ($signed(ex1_ex2_opa) >= $signed(ex1_ex2_opb))) ||
            (ex1_ex2_func3 == 3'b110 && (ex1_ex2_opa <  ex1_ex2_opb)) ||
            (ex1_ex2_func3 == 3'b111 && (ex1_ex2_opa >= ex1_ex2_opb))
        );

    assign branch_target = ex1_ex2_pc + ex1_ex2_imm_out;
    assign jump_target = ex1_ex2_pc + ex1_ex2_imm_out;
    assign jalr_target = (ex1_ex2_opa + ex1_ex2_imm_out) & ~32'd1;

    assign pc_next =
        branch_taken    ? branch_target :
        ex1_ex2_is_jump ? (ex1_ex2_jalr ? jalr_target : jump_target) :
        pc_plus_four;

    // ============================================================
    // 10. EX2/MEM REGISTER (with adc_stall freeze)
    // ============================================================

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ex2_mem_alu_result <= 32'b0;
            ex2_mem_rd2 <= 32'b0;
            ex2_mem_pc_plus_four <= 32'b0;
            ex2_mem_imm_out <= 32'b0;
            ex2_mem_rd <= 5'b0;
            ex2_mem_regf_w <= 1'b0;
            ex2_mem_mem_w <= 1'b0;
            ex2_mem_mem_r <= 1'b0;
            ex2_mem_result_src <= 2'b00;
        end else if (adc_stall) begin
            // FREEZE: keep retrying same address
            ex2_mem_alu_result <= ex2_mem_alu_result;
            ex2_mem_rd2 <= ex2_mem_rd2;
            ex2_mem_pc_plus_four <= ex2_mem_pc_plus_four;
            ex2_mem_imm_out <= ex2_mem_imm_out;
            ex2_mem_rd <= ex2_mem_rd;
            ex2_mem_regf_w <= ex2_mem_regf_w;
            ex2_mem_mem_w <= ex2_mem_mem_w;
            ex2_mem_mem_r <= ex2_mem_mem_r;
            ex2_mem_result_src <= ex2_mem_result_src;
        end else begin
            ex2_mem_alu_result <= ex1_ex2_alu_result;
            ex2_mem_rd2 <= ex1_ex2_opb;
            ex2_mem_pc_plus_four <= ex1_ex2_pc_plus_four;
            ex2_mem_imm_out <= ex1_ex2_imm_out;
            ex2_mem_rd <= ex1_ex2_rd;
            ex2_mem_regf_w <= ex1_ex2_regf_w;
            ex2_mem_mem_w <= ex1_ex2_mem_w;
            ex2_mem_mem_r <= ex1_ex2_mem_r;
            ex2_mem_result_src <= ex1_ex2_result_src;
        end
    end

    // Memory read
    assign mem_data = ex2_mem_mem_r ? ip_buffer[ex2_mem_alu_result[9:2]] : 32'b0;

    // CRITICAL FIX: For loads, forward the DATA not the ADDRESS
    assign ex2_mem_forward_data = ex2_mem_mem_r ? mem_data : ex2_mem_alu_result;

    // ============================================================
    // 11. MEM/WB REGISTER
    // ============================================================

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mem_wb_mem_data <= 32'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_pc_plus_four <= 32'b0;
            mem_wb_imm_out <= 32'b0;
            mem_wb_rd <= 5'b0;
            mem_wb_regf_w <= 1'b0;
            mem_wb_result_src <= 2'b00;
        end else begin
            mem_wb_mem_data <= mem_data;
            mem_wb_alu_result <= ex2_mem_alu_result;
            mem_wb_pc_plus_four <= ex2_mem_pc_plus_four;
            mem_wb_imm_out <= ex2_mem_imm_out;
            mem_wb_rd <= ex2_mem_rd;
            mem_wb_regf_w <= ex2_mem_regf_w;
            mem_wb_result_src <= ex2_mem_result_src;
        end
    end

    // ============================================================
    // 12. WB STAGE
    // ============================================================

    assign write_data =
        (mem_wb_result_src == 2'b00) ? mem_wb_alu_result :
        (mem_wb_result_src == 2'b01) ? mem_wb_mem_data :
        (mem_wb_result_src == 2'b10) ? mem_wb_pc_plus_four :
                                        mem_wb_imm_out;

    // ============================================================
    // 13. FORWARDING UNIT - 3 sources
    // ============================================================

    always @(*) begin
        forward_a_ex = 2'b00;
        forward_b_ex = 2'b00;

        // Priority: EX1/EX2 (newest) → EX2/MEM → MEM/WB
        if (ex1_ex2_regf_w && (ex1_ex2_rd != 5'b0) && (ex1_ex2_rd == id_ex1_rs1))
            forward_a_ex = 2'b11;
        else if (ex2_mem_regf_w && (ex2_mem_rd != 5'b0) && (ex2_mem_rd == id_ex1_rs1))
            forward_a_ex = 2'b10;
        else if (mem_wb_regf_w && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex1_rs1))
            forward_a_ex = 2'b01;

        if (ex1_ex2_regf_w && (ex1_ex2_rd != 5'b0) && (ex1_ex2_rd == id_ex1_rs2))
            forward_b_ex = 2'b11;
        else if (ex2_mem_regf_w && (ex2_mem_rd != 5'b0) && (ex2_mem_rd == id_ex1_rs2))
            forward_b_ex = 2'b10;
        else if (mem_wb_regf_w && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_ex1_rs2))
            forward_b_ex = 2'b01;
    end

    reg [31:0] forward_data_a_r;
always @(*) begin
    case (forward_a_ex)
        2'b11: forward_data_a_r = ex1_ex2_alu_result;
        2'b10: forward_data_a_r = ex2_mem_forward_data;
        2'b01: forward_data_a_r = write_data;
        default: forward_data_a_r = id_ex1_rd1;
    endcase
end
assign forward_data_a = forward_data_a_r;

    reg [31:0] forward_data_b_r;
always @(*) begin
    case (forward_b_ex)
        2'b11: forward_data_b_r = ex1_ex2_alu_result;
        2'b10: forward_data_b_r = ex2_mem_forward_data;
        2'b01: forward_data_b_r = write_data;
        default: forward_data_b_r = id_ex1_rd2;
    endcase
end
assign forward_data_b = forward_data_b_r;

    // ============================================================
    // 14. LOAD-USE HAZARD - FIXED for 6-stage (2-cycle stall)
    // ============================================================

    // Stall if a load is in EX1 or EX2 and its destination is used by
    // the instruction currently in ID (rs1/rs2).
    assign load_use_hazard = (id_ex1_mem_r && (id_ex1_rd != 5'b0) &&
                              ((id_ex1_rd == rs1) || (id_ex1_rd == rs2))) ||
                             (ex1_ex2_mem_r && (ex1_ex2_rd != 5'b0) &&
                              ((ex1_ex2_rd == rs1) || (ex1_ex2_rd == rs2)));

    // ============================================================
    // 15. FLUSH - Squash 3 stages (6-stage pipeline)
    // ============================================================

    assign flush = branch_taken || ex1_ex2_is_jump;

    // ============================================================
// 16. ADC BUFFER
// ============================================================

(* mark_debug = "true" *) reg [31:0] addr_ip_buf;  // FIXED: was 8-bit, deadlocked at sample 255

always @(posedge clk) begin
    if (reset) begin
        addr_ip_buf <= 32'b0;
    end else begin
        if (ip_buf_wr) begin
            ip_buffer[addr_ip_buf[7:0]] <= adc_sample;  // circular: only low 8 bits index buffer
            addr_ip_buf <= addr_ip_buf + 32'b1;          // but counter itself never wraps
        end
    end
end

    // ============================================================
    // 17. CPU OUTPUT + DAC STROBE
    // ============================================================

  always @(posedge clk or posedge reset) begin
    if (reset) begin
        dac_strobe <= 1'b0;
        cpu_output <= 32'b0;
    end
    else if (ex2_mem_mem_w) begin
        cpu_output <= ex2_mem_rd2;
        dac_strobe <= 1'b1;
    end
    else begin
        dac_strobe <= 1'b0;
    end
end

    // ============================================================
// 18. ADC STALL
// ============================================================

// ex2_mem_alu_result[9:2] is 8-bit (0-255), addr_ip_buf is 32-bit.
// Verilog zero-extends the left side. After 256 samples addr_ip_buf=256,
// so 255 >= 256 = false -> stall clears correctly.
assign adc_stall = ex2_mem_mem_r && ({24'b0, ex2_mem_alu_result[9:2]} >= addr_ip_buf);

endmodule