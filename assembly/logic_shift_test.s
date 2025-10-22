# logic_test.s -- and / or
# Expect: r4 = r1 & r2 ; r5 = r1 | r2

nop 

addi $1, $0, 0x0F     # r1 = 15
addi $2, $0, 0xF0     # r2 = 240
and  $4, $1, $2       # r4 = 0x00
or   $5, $1, $2       # r5 = 0xFF

# shift_test.s -- sll and sra
# Expect: r3 = r1 << 3 ; r5 = arithmetic shift right of negative

addi $1, $0, 3        # r1 = 3
sll  $3, $1, 3        # r3 = 3 << 3 = 24

addi $4, $0, -16      # r4 = -16 (0xFFFFFFF0)
sra  $5, $4, 2        # r5 = -4 (arithmetic shift)

nop