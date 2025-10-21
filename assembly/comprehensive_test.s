nop

# Initialize test values
addi $1, $0, 5      # r1 = 5
addi $2, $0, 3      # r2 = 3
addi $3, $0, 7      # r3 = 7
addi $4, $0, 2      # r4 = 2

# Test R-type instructions
add $5, $1, $2      # r5 = r1 + r2 = 5 + 3 = 8
sub $6, $3, $2      # r6 = r3 - r2 = 7 - 3 = 4
and $7, $1, $2      # r7 = r1 & r2 = 5 & 3 = 1
or $8, $1, $2       # r8 = r1 | r2 = 5 | 3 = 7
sll $9, $2, 2       # r9 = r2 << 2 = 3 << 2 = 12
sra $10, $3, 1      # r10 = r3 >> 1 = 7 >> 1 = 3

# Test I-type instructions
addi $11, $0, 100   # r11 = 0 + 100 = 100

# Test memory operations
sw $5, 0($0)        # store r5 (8) at memory address 0
sw $6, 1($0)        # store r6 (4) at memory address 1
sw $7, 2($0)        # store r7 (1) at memory address 2
sw $8, 3($0)        # store r8 (7) at memory address 3
sw $9, 4($0)        # store r9 (12) at memory address 4
sw $10, 5($0)       # store r10 (3) at memory address 5
sw $11, 6($0)       # store r11 (100) at memory address 6

# Test load operations
lw $12, 0($0)       # r12 = load from memory address 0 = 8
lw $13, 1($0)       # r13 = load from memory address 1 = 4
lw $14, 2($0)       # r14 = load from memory address 2 = 1
lw $15, 3($0)       # r15 = load from memory address 3 = 7
lw $16, 4($0)       # r16 = load from memory address 4 = 12
lw $17, 5($0)       # r17 = load from memory address 5 = 3
lw $18, 6($0)       # r18 = load from memory address 6 = 100

# Test complex operations
add $19, $12, $13   # r19 = r12 + r13 = 8 + 4 = 12
sub $20, $15, $14   # r20 = r15 - r14 = 7 - 1 = 6
and $21, $16, $17   # r21 = r16 & r17 = 12 & 3 = 0
or $22, $19, $20    # r22 = r19 | r20 = 12 | 6 = 14

# Test more shift operations
sll $23, $1, 3      # r23 = r1 << 3 = 5 << 3 = 40
sra $24, $18, 2     # r24 = r18 >> 2 = 100 >> 2 = 25

# Test immediate operations
addi $25, $0, 255   # r25 = 255
addi $26, $0, -1    # r26 = -1 (should be 0xFFFFFFFF)

# Final memory operations
sw $19, 7($0)       # store r19 (12) at memory address 7
sw $20, 8($0)       # store r20 (6) at memory address 8
sw $21, 9($0)       # store r21 (0) at memory address 9
sw $22, 10($0)      # store r22 (14) at memory address 10
sw $23, 11($0)      # store r23 (40) at memory address 11
sw $24, 12($0)      # store r24 (25) at memory address 12
sw $25, 13($0)      # store r25 (255) at memory address 13
sw $26, 14($0)      # store r26 (-1) at memory address 14

nop
