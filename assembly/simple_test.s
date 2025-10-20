nop

addi $1, $0, 5  # r1 = 5
sw $1, 0($0)    # store r1 to memory[0]
lw $2, 0($0)    # load memory[0] to r2
nop             # halt