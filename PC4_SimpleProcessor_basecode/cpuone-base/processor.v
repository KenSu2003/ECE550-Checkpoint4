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
    
    // Program Counter
    reg [11:0] pc;
    
    // Instruction fields
    wire [5:0] opcode;
    wire [4:0] rs, rt, rd, shamt;
    wire [5:0] funct;
    wire [15:0] immediate;
    wire [31:0] sign_extended_immediate;
    
    // Control signals
    reg reg_write, mem_write, mem_read;
    reg [4:0] alu_op;
    reg alu_src;
    
    // ALU signals
    wire [31:0] alu_input_a, alu_input_b, alu_result;
    wire alu_zero, alu_overflow;
    
    // Extract instruction fields
    assign opcode = q_imem[31:26];
    assign rs = q_imem[25:21];
    assign rt = q_imem[20:16];
    assign rd = q_imem[15:11];
    assign shamt = q_imem[10:6];
    assign funct = q_imem[5:0];
    assign immediate = q_imem[15:0];
    assign sign_extended_immediate = {{16{immediate[15]}}, immediate};
    
    // Connect to memory and register file
    assign address_imem = pc;
    assign ctrl_readRegA = rs;
    assign ctrl_readRegB = rt;
    assign ctrl_writeReg = (opcode == 6'b000000) ? rd : rt;
    assign data_writeReg = mem_read ? q_dmem : alu_result;
    // Prevent writing to register 0
    assign ctrl_writeEnable = reg_write && (ctrl_writeReg != 5'b00000);
    
    assign address_dmem = alu_result[11:0];
    assign data = data_readRegB;
    assign wren = mem_write;
    
    // ALU connections
    assign alu_input_a = data_readRegA;
    assign alu_input_b = alu_src ? sign_extended_immediate : data_readRegB;
    
    // Instantiate ALU
    alu my_alu(
        .data_operandA(alu_input_a),
        .data_operandB(alu_input_b),
        .ctrl_ALUopcode(alu_op),
        .ctrl_shiftamt(shamt),
        .data_result(alu_result),
        .isNotEqual(alu_zero),
        .isLessThan(),
        .overflow(alu_overflow)
    );
    
    // Control logic
    always @(*) begin
        // Default values
        reg_write = 0;
        mem_write = 0;
        mem_read = 0;
        alu_op = 0;
        alu_src = 0;
        
        case (opcode)
            6'b000000: begin // R-type instructions
                reg_write = 1;
                alu_src = 0;
                case (funct)
                    6'b100000: alu_op = 0; // add
                    6'b100010: alu_op = 1; // sub
                    6'b100100: alu_op = 2; // and
                    6'b100101: alu_op = 3; // or
                    6'b000000: alu_op = 4; // sll
                    6'b000011: alu_op = 5; // sra
                endcase
            end
            6'b001000: begin // addi
                reg_write = 1;
                alu_src = 1;
                alu_op = 0; // add
            end
            6'b101011: begin // sw
                mem_write = 1;
                alu_src = 1;
                alu_op = 0; // add
            end
            6'b100011: begin // lw
                reg_write = 1;
                mem_read = 1;
                alu_src = 1;
                alu_op = 0; // add
            end
        endcase
    end
    
    // PC update
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            pc <= 0;
        end else begin
            pc <= pc + 1;
        end
    end

endmodule