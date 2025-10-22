# lw_sw_test.s -- basic store/load checks (rd is store source)
# Expect: MEM[10]=77; r6=77 after lw

nop

addi $1, $0, 77        # r1 = 77 (value to store)
addi $2, $0, 10        # r2 = 10 (base)
sw   $1, 0($2)         # MEM[10] = r1
lw   $6, 0($2)         # r6 := MEM[10] -> 77

# also negative offset test
lw   $7, -1($2)        # load from MEM[9] (if initialized)

nop