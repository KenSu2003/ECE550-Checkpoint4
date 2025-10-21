/**
 * READ THIS DESCRIPTION!
 *
 * The processor takes in several inputs from a skeleton file.
 *
 * Inputs
 * clock: this is the clock for your processor at 50 MHz
 * reset: we should be able to assert a reset to start your pc from 0 (sync or
 * async is fine)
 *
 * Imem: input data from imem
 * Dmem: input data from dmem
 * Regfile: input data from regfile
 *
 * Outputs
 * Imem: output control signals to interface with imem
 * Dmem: output control signals and data to interface with dmem
 * Regfile: output control signals and data to interface with regfile
 *
 * Notes
 *
 * Ultimately, your processor will be tested by subsituting a master skeleton, imem, dmem, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file acts as a small wrapper around your processor for this purpose.
 *
 * You will need to figure out how to instantiate two memory elements, called
 * "syncram," in Quartus: one for imem and one for dmem. Each should take in a
 * 12-bit address and allow for storing a 32-bit value at each address. Each
 * should have a single clock.
 *
 * Each memory element should have a corresponding .mif file that initializes
 * the memory element to certain value on start up. These should be named
 * imem.mif and dmem.mif respectively.
 *
 * Importantly, these .mif files should be placed at the top level, i.e. there
 * should be an imem.mif and a dmem.mif at the same level as process.v. You
 * should figure out how to point your generated imem.v and dmem.v files at
 * these MIF files.
 *
 * imem
 * Inputs:  12-bit address, 1-bit clock enable, and a clock
 * Outputs: 32-bit instruction
 *
 * dmem
 * Inputs:  12-bit address, 1-bit clock, 32-bit data, 1-bit write enable
 * Outputs: 32-bit data at the given address
 *
 */
module processor(
    // Control signals
    clock,                          // I: The master clock
    reset,                          // I: A reset signal

    // Imem
    address_imem,                   // O: The address of the data to get from imem
    q_imem,                         // I: The data from imem

    // Dmem
    address_dmem,                   // O: The address of the data to get or put from/to dmem
    data,                           // O: The data to write to dmem
    wren,                           // O: Write enable for dmem
    q_dmem,                         // I: The data from dmem

    // Regfile
    ctrl_writeEnable,               // O: Write enable for regfile
    ctrl_writeReg,                  // O: Register to write to in regfile
    ctrl_readRegA,                  // O: Register to read from port A of regfile
    ctrl_readRegB,                  // O: Register to read from port B of regfile
    data_writeReg,                  // O: Data to write to for regfile
    data_readRegA,                  // I: Data from port A of regfile
    data_readRegB                   // I: Data from port B of regfile
);

    // Control signals
    input clock, reset;

    // Imem
    output [11:0] address_imem;
    input [31:0] q_imem;

    // Dmem
    output [11:0] address_dmem;
    output [31:0] data;
    output wren;
    input [31:0] q_dmem;

    // Regfile
    output ctrl_writeEnable;
    output [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input [31:0] data_readRegA, data_readRegB;

        /* YOUR CODE STARTS HERE */
    
    /* ———————————————————— IF/ID Stage ———————————————————— */
    reg [11:0] pc;
    wire [11:0] pc_plus_1, pc_next;
    wire pc_src;
    
    // PC+1 calculation
    assign pc_plus_1 = pc + 1;
    
    // Branch Target Calculation
    wire [11:0] branch_target;
    assign branch_target = pc_plus_1;  // For now, same as pc_plus_1 since no branches
    
    // PC Source Mux
    mux_2_1 pc_mux (
        .out(pc_next),
        .a(pc_plus_1),
        .b(branch_target),
        .s(pc_src)
    );
    
    // PC update
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            pc <= 0;
        end else begin
            pc <= pc_next;
        end
    end
    
    // PC -> Read Address
    assign address_imem = pc;
    
    /* ———————————————————— ID/EX Stage ———————————————————— */
    wire [4:0] opcode;
    wire [4:0] rs, rt, rd, shamt;
    wire [4:0] alu_op;
    wire [16:0] immediate;
    wire [31:0] sign_extended;
    wire [1:0] zeroes;
    
    assign opcode = q_imem[31:27];
    assign rd = q_imem[26:22];
    assign rs = q_imem[21:17];
    assign rt = q_imem[16:12];
    assign shamt = q_imem[11:7];
    assign alu_op = q_imem[6:2];
    assign zeroes = q_imem[1:0];
    assign immediate = q_imem[16:0];
    assign sign_extended = {{15{immediate[16]}}, immediate};

    assign ctrl_readRegA = rs;  // Read register 1
    assign ctrl_readRegB = rt;  // Read register 2

    
    /* ———————————————————— Control Unit ———————————————————— */
    
    wire mem_read, mem_to_reg, mem_write, alu_src, reg_write, reg_dst;
    
    // Instruction types
    wire r_type, addi_type, lw_type, sw_type;
    
    // R-type (opcode == 5'b00000)
    and r_type_check (r_type, ~opcode[4], ~opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);
    
    // addi (opcode == 5'b00101)
    and addi_check (addi_type, ~opcode[4], ~opcode[3], opcode[2], ~opcode[1], opcode[0]);
    
    // lw (opcode == 5'b01000)
    and lw_check (lw_type, ~opcode[4], opcode[3], ~opcode[2], ~opcode[1], ~opcode[0]);
    
    // sw (opcode == 5'b00111)
    and sw_check (sw_type, ~opcode[4], ~opcode[3], opcode[2], opcode[1], opcode[0]);
    
    // Control signals (action:type) , bitwise logical opetaion is ALLOWED
    assign reg_write = r_type | addi_type | lw_type;
    assign mem_write = sw_type;
    assign mem_read = lw_type;
    assign reg_dst = r_type;
    assign alu_src = addi_type | lw_type | sw_type;
    assign mem_to_reg = lw_type;
    assign pc_src = 1'b0;  // No branches in this checkpoint
        
    /* ———————————————————— EX/MEM ———————————————————— */
    // Mentioned above, here is where our write register is set
    wire [4:0] write_reg;
    mux_2_1 reg_dst_mux (
        .out(write_reg),
        .a(rt),
        .b(rd),
        .s(reg_dst)
    );
    assign ctrl_writeReg = write_reg;
    
    // ALU Source Mux
    wire [31:0] alu_src_b;
    mux_2_1 alu_src_mux (
        .out(alu_src_b),
        .a(data_readRegB),
        .b(sign_extended),
        .s(alu_src)
    );
    
    // ALU
    wire [31:0] alu_result;
    wire alu_zero;
    wire overflow;
    
    // ALU operation selection
    wire add_op, sub_op, and_op, or_op, sll_op, sra_op;
    
    // R-type function codes
    wire add_func, sub_func, and_func, or_func, sll_func, sra_func;
    and add_gate (add_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sub_gate (sub_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], ~alu_op[1], alu_op[0]);
    and and_gate (and_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], ~alu_op[0]);
    and or_gate (or_func, ~alu_op[4], ~alu_op[3], ~alu_op[2], alu_op[1], alu_op[0]);
    and sll_gate (sll_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], ~alu_op[0]);
    and sra_gate (sra_func, ~alu_op[4], ~alu_op[3], alu_op[2], ~alu_op[1], alu_op[0]);
    
    assign add_op = r_type & add_func | addi_type;
    assign sub_op = r_type & sub_func;
    assign and_op = r_type & and_func;
    assign or_op = r_type & or_func;
    assign sll_op = r_type & sll_func;
    assign sra_op = r_type & sra_func;
    
    // ALU control
    wire [4:0] alu_control;
    assign alu_control = add_op ? 5'b00000 :
                         sub_op ? 5'b00001 :
                         and_op ? 5'b00010 :
                         or_op ? 5'b00011 :
                         sll_op ? 5'b00100 :
                         sra_op ? 5'b00101 :
                         5'b00000;
    
    // ALU instantiation
    alu main_alu (
        .data_operandA(data_readRegA),
        .data_operandB(alu_src_b),
        .ctrl_ALUopcode(alu_control),
        .ctrl_shiftamt(shamt),
        .data_result(alu_result),
        .isNotEqual(alu_zero),
        .isLessThan(),
        .overflow(overflow)
    );
    
    // Overflow handling
    wire [31:0] rstatus;
    assign rstatus = (add_op & overflow) ? 32'd1 :
                     (addi_type & overflow) ? 32'd2 :
                     (sub_op & overflow) ? 32'd3 :
                     32'd0;
    
    /* ———————————————————— MEM/WB Stage ———————————————————— */
    // Memory Interface
    assign address_dmem = alu_result[11:0];
    assign data = data_readRegB;
    assign wren = mem_write;
    
    /* ———————————————————— WB Stage ———————————————————— */
    // Memory to Register Mux
    mux_2_1 mem_to_reg_mux (
        .out(data_writeReg),
        .a(alu_result),
        .b(q_dmem),
        .s(mem_to_reg)
    );
    
    // Register write enable
    assign ctrl_writeEnable = reg_write;
    
endmodule