# add_test.s -- basic add
# Expect: r3 = r1 + r2 = 7 + 5 = 12
nop

addi $1, $0, 7        # r1 = 7
addi $2, $0, 5        # r2 = 5
add  $3, $1, $2       # r3 = r1 + r2

# addi_test.s -- addi and sign-extension edgecases
# Expect: r1=7, r2=-3, r3 = r1 + (-3) = 4
# Also test boundary immediates: +65535 and -65536

addi $1, $0, 7         # r1 = 7
addi $2, $0, -3        # r2 = -3 (sign-extended 17-bit)
addi $3, $1, -3        # r3 = 4

# boundary positive immediate
addi $4, $0, 65535     # r4 = +65535 (max 17-bit positive)
# boundary negative immediate
addi $5, $0, -65536    # r5 = -65536 (min 17-bit negative)

# sub_test.s -- basic subtraction
# Expect: r3 = r2 - r1 = 9 - 4 = 5

addi $1, $0, 4        # r1=4
addi $2, $0, 9        # r2=9
sub  $3, $2, $1       # r3=5