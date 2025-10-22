# overflow_test.s -- provoke add/addi/sub overflow and check $r30 rstatus writes
# We use registers <= 31

nop

# Build 0x40000000 in r20 then add it to itself to overflow signed
addi $20, $0, 1
sll  $20, $20, 30      # r20 = 0x40000000
add  $21, $20, $20     # r21 = r20 + r20 -> 0x80000000 (signed overflow) -> r30 = 1

# addi overflow edge: construct 0x7FFFFFFF then add immediate +1
addi $28, $0, 32767
sll  $28, $28, 16      # 0x7FFF0000
addi $28, $28, 65535   # 0x7FFFFFFF
addi $28, $28, 1       # overflow -> r30 = 2

# sub overflow: r29 = 0x80000000 ; sub r29 - 1 -> 0x7FFFFFFF signed overflow
addi $29, $0, 1
sll  $29, $29, 31      # r29 = 0x80000000
sub  $23, $29, $1      # subtract 1 -> overflow -> r30 = 3

nop