nop

# Block A: Initialize registers (addresses 0..4)
addi $1,  $0,   7        # $1 = 7
addi $2,  $0,  13        # $2 = 13
addi $3,  $0,  -5        # $3 = -5 (sign-extended)
addi $5,  $0, 100        # $5 = 100  (base for memory tests)
addi $12, $0,   1        # $12 = 1   (for shifts)

# Block B: R-type arithmetic (addresses 5..8)
add  $6,  $1,  $2        # $6 = $1 + $2  => 20
sub  $7,  $2,  $1        # $7 = $2 - $1  => 6
and  $8,  $1,  $2        # $8 = 7 & 13
or   $9,  $1,  $2        # $9 = 7 | 13

# Block C: addi and sign-extension (addresses 9..10)
addi $10, $1,  -3        # $10 = 7 + (-3) => 4
addi $11, $3,   1        # $11 = -5 + 1 => -4

# Block D: shifts (addresses 11..13)
sll  $13, $12,  4        # $13 = 1 << 4 => 16
addi $14, $0, -16        # $14 = -16
sra  $15, $14,  2        # $15 = -16 >>> 2 => -4

# Block E: memory store/load round-trip (addresses 14..15)
# store $6 (which should be 20) into MEM[$5 + 3] => MEM[103]
sw   $6,  3($5)          # MEM[103] = $6 (20)
lw   $7,  3($5)          # $7 = MEM[103] => overwrites $7 with 20

# Block F: add overflow using shifts (addresses 16..18)
# Construct $20 = 1 << 30 = 0x4000_0000
addi $20, $0, 1          # $20 = 1
sll  $20, $20, 30        # $20 = 1 << 30 = 0x40000000
add  $21, $20, $20       # $21 = $20 + $20 => 0x80000000 (signed overflow)
# After this ADD, rstatus should be set to 1 in $30 (exception write)

# Block G: addi overflow (addresses 19..22)
# Create value close to INT_MAX:
#  1) $28 = 32767
#  2) $28 <<= 16 -> 32767 << 16 = 0x7FFF0000
#  3) addi $28, $28, 65535 -> 0x7FFFFFFF (INT_MAX)
#  4) addi $28, $28, 1 -> overflow to 0x80000000 -> rstatus = 2
addi $28, $0, 32767      # $28 = 32767
sll  $28, $28, 16        # $28 <<= 16 => 0x7FFF0000
addi $28, $28, 65535     # $28 = 0x7FFF0000 + 65535 => 0x7FFFFFFF (INT_MAX)
addi $28, $28, 1         # overflow -> $28 becomes 0x80000000 and rstatus=2 in $30

# Block H: sub overflow (addresses 23..25)
# Create $29 = 1 << 31 = 0x80000000 (most-negative)
addi $29, $0, 1          # $29 = 1
sll  $29, $29, 31        # $29 = 1 << 31 = 0x80000000 (signed MIN)
# Now compute $23 = $29 - $12  => 0x80000000 - 1 => 0x7FFFFFFF -> signed overflow
sub  $23, $29, $12       # causes overflow -> rstatus = 3 in $30

# Block I: Synthetic mini-program (addresses 26..33)
# compute idx = $1 + 4 => put 999 at MEM[$5 + idx]
addi $16, $1, 4          # $16 = $1 + 4   ; idx = 11
addi $17, $0, 999        # $17 = 999      ; value to store
sw   $17, 11($5)         # MEM[$5 + 11] = 999
lw   $18, 11($5)         # $18 = MEM[$5 + 11] => 999
add  $19, $18, $6        # $19 = $18 + $6  => 999 + 20 = 1019

# Halt (fill rest with zeros or NOP-equivalent if assembler supports)
# (If your assembler has a 'halt' or 'nop', you can place it; otherwise fill remaining imem with zeros.)

# --- ADDI edge cases (covers sign-extension & bounds) ---
# Large positive immediate (max 17-bit = +65535)
addi $30, $0, 65535       # $30 = 65535  (use temp reg; note $30 is rstatus in ISA — if using r30 for exceptions, choose another reg like $24 instead)
# (If you used $30 above for a temp, you may want to use $24 to avoid collision with rstatus)
addi $24, $0, 65535       # $24 = +65535  (boundary +)

# Large negative immediate (min 17-bit = -65536)
addi $25, $0, -65536      # $25 = -65536 (boundary -)

# Use addi as address calculation for lw/sw
# store $1 into MEM[$5 + 0] and MEM[$5 - 1] (negative offset)
sw   $1, 0($5)            # MEM[$5 + 0] = $1 (7)
sw   $1, -1($5)           # MEM[$5 - 1] = $1 (tests negative offset)
lw   $26, 0($5)           # $26 = MEM[$5 + 0] -> should be 7
lw   $27, -1($5)          # $27 = MEM[$5 - 1] -> should be 7

# --- LW/SW permutations (cover different rd/rs combinations) ---
# Put value in $3 and store it using sw (rd-case)
sw   $3, 5($5)            # MEM[$5 + 5] = $3 (-5)
lw   $14, 5($5)           # $14 = MEM[$5 + 5] -> should be -5

# Use another store where rd != rt
addi $2, $0, 21           # $2 = 21  (ensure $2 changed)
sw   $2, 7($5)            # MEM[$5 + 7] = $2 (21)
lw   $8, 7($5)            # $8 = 21

# Write to multiple memory addresses and read them back
sw   $6, 1($5)            # MEM[$5 + 1] = 20
sw   $9, 2($5)            # MEM[$5 + 2] = ($9 from earlier)
lw   $21, 1($5)           # $21 = 20
lw   $22, 2($5)           # $22 = $9

# --- Overflow extra edgecases (ensure rstatus write and override) ---
# Make values that will overflow via addi using immediate boundary
# Prepare: set $31 (tmp) = 0x7FFF0000 (like earlier), then addi by +65535 -> INT_MAX, then addi +1 -> overflow
addi $31, $0, 32767       # $31 = 32767
sll  $31, $31, 16         # $31 <<=16 -> 0x7FFF0000
addi $31, $31, 65535      # $31 = 0x7FFFFFFF (INT_MAX)
addi $31, $31, 1          # overflow -> $30 should be set to 2 (check rstatus immed after this)

# # Another add overflow variant: add with reg that causes overflow
# # Prepare registers for a second add overflow
# addi $40, $0, 1           # $40 = 1
# sll  $40, $40, 30         # $40 = 0x40000000
# # create two regs to add to overflow
# add  $41, $40, $40        # $41 = 0x80000000 -> overflow -> rstatus = 1

# # Sub overflow variant (mirror): create min and subtract causing overflow
# addi $42, $0, 1
# sll  $42, $42, 31         # $42 = 0x80000000 (INT_MIN)
# sub  $43, $42, $12        # $43 will overflow signed -> rstatus = 3

# # --- Small synthetic sequence (no branches)
# # compute address = $5 + 20, store then load and compute
# addi $50, $5, 20          # $50 = $5 + 20  (address)
# addi $51, $0, 1234        # $51 = 1234
# sw   $51, 20($5)          # MEM[$5 + 20] = 1234
# lw   $52, 20($5)          # $52 = 1234
# add  $53, $52, $6         # $53 = 1234 + 20 = 1254

nop