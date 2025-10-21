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

## Module Descriptions

### processor.v
The main processor module that implements the single-cycle MIPS datapath. It includes PC management, instruction decoding, control unit logic, ALU operations, and memory interface. The module handles all required R-type and I-type instructions with proper overflow detection and register file management.

### alu.v
Arithmetic Logic Unit that performs 32-bit arithmetic and logical operations including addition, subtraction, bitwise AND/OR, and shift operations. It outputs the result, zero flag, and overflow detection for proper processor operation.

### regfile.v
32-register register file with dual read ports and single write port. Supports simultaneous reading of two registers and writing to one register per cycle, with register 0 hardwired to always read as zero.

### mux_2_1.v
2-to-1 multiplexer module used throughout the datapath for selecting between different data sources, including ALU input selection, register destination selection, and memory-to-register selection.

### imem.v
Instruction memory module that stores and provides 32-bit instructions based on 12-bit addresses. Initialized from MIF files containing the test programs.

### dmem.v
Data memory module for storing and retrieving 32-bit data words. Supports both read and write operations with 12-bit addressing and write enable control.

## Test Programs

### simple_test.s
Basic test program that initializes a register, stores it to memory, and loads it back to verify basic memory operations.

### basic_test.s
Comprehensive test program that exercises all R-type and I-type instructions including arithmetic, logical, and shift operations with memory store/load operations.

### comprehensive_test.s
Extended test program that thoroughly tests all instruction types with complex operations, edge cases, and memory operations to verify complete processor functionality.

## Known Issues

**PC Increment Issue:** Initially implemented PC+4 increment which caused incorrect instruction fetching. Fixed by changing to PC+1 increment to match word-addressed memory architecture.

**Control Signal Logic:** Had to reimplement control unit using primitive gates instead of behavioral constructs to comply with structural Verilog requirements.

**ALU Overflow Handling:** Implemented proper overflow detection with rstatus register updates for add, addi, and sub operations as specified in the ISA.

**Branch Instructions:** Branch and isLessThan has not been implemented.

## Design Verification

The processor successfully executes all required instructions and passes the provided test programs. The implementation correctly handles word-addressed memory, proper PC increment, and all control signal generation without using prohibited behavioral constructs.
