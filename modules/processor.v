/**
 * Processor (fixed: decoder before use)
 *
 * Structural-only processor implementation for Checkpoint 4:
 * - R-type and I-type (add, addi, sub, and, or, sll, sra, lw, sw)
 * - Uses ALU for arithmetic (no '+' in top-level)
 * - No behavioral constructs (no always/case) in this file
 */
module processor(
    // Control signals
    clock,
    reset,

    // Imem
    address_imem,
    q_imem,

    // Dmem
    address_dmem,
    data,
    wren,
    q_dmem,

    // Regfile
    ctrl_writeEnable,
    ctrl_writeReg,
    ctrl_readRegA,
    ctrl_readRegB,
    data_writeReg,
    data_readRegA,
    data_readRegB
);

    input clock, reset;

    output [11:0] address_imem;
    input  [31:0] q_imem;

    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input  [31:0] q_dmem;

    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input  [31:0] data_readRegA, data_readRegB;

    /* ---------------------------------------------------------------------
       IF/ID stage: PC and fetch
       --------------------------------------------------------------------- */

    wire [11:0] pc;
    wire [11:0] pc_plus_1, pc_next;
    wire pc_src;
    assign pc_src = 1'b0;

    wire [31:0] pc_alu_result;
    alu pc_alu (
        .data_operandA({20'b0, pc}),
        .data_operandB(32'd1),
        .ctrl_ALUopcode(5'b00000),
        .ctrl_shiftamt(5'b00000),
        .data_result(pc_alu_result),
        .isNotEqual(),
        .isLessThan(),
        .overflow()
    );
    assign pc_plus_1 = pc_alu_result[11:0];

    wire [11:0] branch_target;
    assign branch_target = pc_plus_1;

    mux_2_1 pc_mux (
        .out(pc_next),
        .a(pc_plus_1),
        .b(branch_target),
        .s(pc_src)
    );

    genvar i;
    generate
        for (i = 0; i < 12; i = i + 1) begin : pc_reg_gen
            dffe_ref pc_dffe_i (
                .q(pc[i]),
                .d(pc_next[i]),
                .clk(clock),
                .en(1'b1),
                .clr(reset)
            );
        end
    endgenerate

    assign address_imem = pc;

    /* ---------------------------------------------------------------------
       ID stage: instruction decode / fields
       --------------------------------------------------------------------- */

    wire [4:0] opcode;
    wire [4:0] rs, rt, rd, shamt;
    wire [4:0] alu_op;
    wire [16:0] immediate;
    wire [31:0] sign_extended;

    assign opcode    = q_imem[31:27];
    assign rd        = q_imem[26:22]; // destination for R-type and I-type in this ISA
    assign rs        = q_imem[21:17];
    assign rt        = q_imem[16:12];
    assign shamt     = q_imem[11:7];
    assign alu_op    = q_imem[6:2];
    assign immediate = q_imem[16:0];

    assign sign_extended = {{15{immediate[16]}}, immediate};

    /* ---------------------------------------------------------------------
       Control unit (decoder) — moved here so sw_type exists before use
       --------------------------------------------------------------------- */

    wire mem_read, mem_to_reg, mem_write, alu_src, reg_write;
    wire r_type, addi_type, lw_type, sw_type;

    // r_type: opcode == 00000
    and r_type_check (r_type, ~opcode[4], ~opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);
    // addi: opcode == 00101
    and addi_check (addi_type, ~opcode[4], ~opcode[3], opcode[2], ~opcode[1], opcode[0]);
    // lw: opcode == 01000
    and lw_check (lw_type, ~opcode[4], opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);
    // sw: opcode == 00111
    and sw_check (sw_type, ~opcode[4], ~opcode[3], opcode[2], opcode[1], opcode[0]);

    assign reg_write = r_type | addi_type | lw_type;
    assign mem_write = sw_type;
    assign mem_read  = lw_type;
    assign alu_src   = addi_type | lw_type | sw_type;
    assign mem_to_reg = lw_type;

    /* ---------------------------------------------------------------------
       Regfile read ports:
       ctrl_readRegA = rs
       ctrl_readRegB = rd when sw (store) else rt
       --------------------------------------------------------------------- */

    assign ctrl_readRegA = rs;
    assign ctrl_readRegB = sw_type ? rd : rt; // fix: sw uses $rd as store data

    /* ---------------------------------------------------------------------
       EX stage: ALU inputs and control
       --------------------------------------------------------------------- */

    wire add_func, sub_func, and_func, or_func, sll_func, sra_func;
    and add_gate (add_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sub_gate (sub_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], alu_op[0]);
    and and_gate (and_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], ~alu_op[0]);
    and or_gate  (or_func,  ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], alu_op[0]);
    and sll_gate (sll_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sra_gate (sra_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], alu_op[0]);

    wire add_op, sub_op, and_op, or_op, sll_op, sra_op;
    assign add_op = (r_type & add_func) | addi_type;
    assign sub_op = r_type & sub_func;
    assign and_op = r_type & and_func;
    assign or_op  = r_type & or_func;
    assign sll_op = r_type & sll_func;
    assign sra_op = r_type & sra_func;

    wire [4:0] alu_control;
    assign alu_control = add_op ? 5'b00000 :
                         sub_op ? 5'b00001 :
                         and_op ? 5'b00010 :
                         or_op  ? 5'b00011 :
                         sll_op ? 5'b00100 :
                         sra_op ? 5'b00101 :
                         5'b00000;

    wire [31:0] alu_src_b;
    mux_2_1 alu_src_mux (
        .out(alu_src_b),
        .a(data_readRegB),
        .b(sign_extended),
        .s(alu_src)
    );

    wire [31:0] alu_result;
    wire alu_isNotEqual;
    wire alu_isLessThan;
    wire alu_overflow;
    alu main_alu (
        .data_operandA(data_readRegA),
        .data_operandB(alu_src_b),
        .ctrl_ALUopcode(alu_control),
        .ctrl_shiftamt(shamt),
        .data_result(alu_result),
        .isNotEqual(alu_isNotEqual),
        .isLessThan(alu_isLessThan),
        .overflow(alu_overflow)
    );

    /* ---------------------------------------------------------------------
       Overflow / rstatus handling
       --------------------------------------------------------------------- */

    wire [31:0] rstatus;
    assign rstatus = (add_op & alu_overflow) ? 32'd1 :
                     (addi_type & alu_overflow) ? 32'd2 :
                     (sub_op & alu_overflow) ? 32'd3 :
                     32'd0;

    wire overflow_exception;
    assign overflow_exception = ((add_op | addi_type | sub_op) & alu_overflow);

    /* ---------------------------------------------------------------------
       MEM stage: memory interface
       --------------------------------------------------------------------- */

    assign address_dmem = alu_result[11:0];
    assign data = data_readRegB;
    assign wren = mem_write;

    /* ---------------------------------------------------------------------
       WB stage: final write selection, exception overrides, r0 protection
       --------------------------------------------------------------------- */

    wire [4:0] normal_write_reg;
    assign normal_write_reg = rd;

    wire [31:0] mem_to_reg_data;
    mux_2_1 mem_to_reg_mux (
        .out(mem_to_reg_data),
        .a(alu_result),
        .b(q_dmem),
        .s(mem_to_reg)
    );

    wire [4:0] final_write_reg;
    wire [31:0] final_write_data;
    assign final_write_reg  = overflow_exception ? 5'd30 : normal_write_reg;
    assign final_write_data = overflow_exception ? rstatus : mem_to_reg_data;

    wire final_write_enable;
    assign final_write_enable = reg_write | overflow_exception;

    wire final_is_reg0;
    assign final_is_reg0 = ~( | final_write_reg );

    wire gated_write_enable;
    assign gated_write_enable = final_write_enable & ~final_is_reg0;

    assign ctrl_writeEnable = gated_write_enable;
    assign ctrl_writeReg    = final_write_reg;
    assign data_writeReg    = final_write_data;

endmodule
