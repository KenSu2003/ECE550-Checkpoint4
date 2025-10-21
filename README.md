# Single-Cycle MIPS Processor Implementation

**Name:** Ken Su
**NetID:** hs452

## Design Implementation

I implemented a single-cycle MIPS processor following the provided schematic and custom ISA specification. Reference from: https://enesharman.medium.com/single-cycle-vs-multi-cycle-processors-1c5bf468c569

### Key Design Decisions

**PC Increment:** I used PC+1 increment instead of PC+4 because the memory is word-addressed (32 bits per read/write), where each address corresponds to one 32-bit instruction word.

**Control Unit:** I implemented the control unit using primitive `and` gates to detect opcodes and generate control signals, avoiding `==` comparisons which are not allowed in structural Verilog.

**Pipeline Organization:** I organized the code into pipeline stages (IF/ID, ID/EX, EX/MEM, MEM/WB) for clarity and maintainability.

**ALU Control:** I used ternary operators to select ALU operations based on instruction type and function codes, with separate logic for R-type and I-type instructions.

## Main Modules
- skeleton.v (top-level)
- processor.v
    - imem.v
    - regfile.v
    - dmem.v
    - alu.v
    - mux_2_1.v

## Note 
- Branch and isLessThan has not been implemented.
- Opcode is [31:27] not [31:26] like the diagrams.

