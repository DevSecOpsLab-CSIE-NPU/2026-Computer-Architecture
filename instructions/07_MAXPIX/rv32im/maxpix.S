    .text
    .align  2
    .globl  maxpix_rv32im
    .type   maxpix_rv32im, @function

# uint32_t maxpix_rv32im(uint32_t packed_pixels)
# a0 contains b3:b2:b1:b0. Return max(b0, b1, b2, b3) in a0.
# Uses only RV32I instructions; no memory access and no callee-saved regs.
maxpix_rv32im:
    andi    t0, a0, 255

    srli    t1, a0, 8
    andi    t1, t1, 255
    sltu    t2, t0, t1
    beqz    t2, .Lcheck_b2
    mv      t0, t1

.Lcheck_b2:
    srli    t1, a0, 16
    andi    t1, t1, 255
    sltu    t2, t0, t1
    beqz    t2, .Lcheck_b3
    mv      t0, t1

.Lcheck_b3:
    srli    t1, a0, 24
    andi    t1, t1, 255
    sltu    t2, t0, t1
    beqz    t2, .Lreturn
    mv      t0, t1

.Lreturn:
    mv      a0, t0
    ret
    .size   maxpix_rv32im, .-maxpix_rv32im
