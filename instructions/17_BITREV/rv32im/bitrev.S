# =============================================================================
# bitrev.S — BITREV (32-bit 位元反轉) 的 RV32IM 實作
# -----------------------------------------------------------------------------
# 組別: group17_BITREV      負責人: Chen Jie-Xin (1114405042)
# 對應 Checkpoint: CP2
#
# 語意 (HOMEWORK.md 6.5):
#     rd[i] = rs1[31 - i],  i = 0 .. 31
#     即 0x12345678 -> 0x1E6A2C48
#
# 演算法: 分治 5 步遮罩交換 (divide & conquer, 16 / 8 / 4 / 2 / 1 位元組)
#     step1  交換兩個 16-bit 半字
#     step2  交換每個 16-bit 半字內的兩個 8-bit byte
#     step3  交換每個 byte 內的兩個 4-bit nibble
#     step4  交換每個 nibble 內的兩個 2-bit 群組
#     step5  交換相鄰的兩個單一位元
#     與 CP1 的 C baseline (src/c_baseline/bitrev.c) 同構, 順序一致 (16->8->4->2->1)
#
# 本檔分成兩個部分:
#   [1] bitrev       : 純 RV32IM 函式 (只用 base I 指令, 無 ecall, 無分支)
#   [2] 測試 harness : Ripes 專用 (用 Ripes 的 ecall 輸出), 跑 CP1 的 11 組測資
#
# 執行方式:
#   Ripes GUI : 開啟本檔 -> 檢視 Register -> Run
#   Ripes CLI : Ripes --mode cli --src bitrev.S -t asm --proc RV32_5S \
#                      --isaexts M --iret --cycles --regs
# =============================================================================

    .text
    .globl  _start

# Ripes 的 bare 模式從 .text 最低位址開始執行, 因此入口先跳到測試主程式。
_start:
    j       test_main

# =============================================================================
# [1] bitrev — 核心函式 (純 RV32IM)
# -----------------------------------------------------------------------------
# 介面: uint32_t bitrev(uint32_t x)   a0 = 輸入, a0 = 輸出
# 呼叫慣例: leaf function, 不保存任何暫存器, 不使用堆疊, 破壞 a0/t0-t3
# 分支數: 0 (完全無分支, 指令數與輸入值無關)
#
# 暫存器配置:
#   a0  輸入 x / 輸出結果 (每一步就地更新)
#   t0  U(k) 遮罩: 標記「要往下移」的那半邊 (高半邊的位元群組)
#   t1  L(k) 遮罩: 標記「要往上移」的那半邊 (低半邊的位元群組)
#   t2  中間值: (x & L) << k
#   t3  中間值: (x & U) >> k
#
# 遮罩表 (k = 一次移動的位元組大小):
#   k=16  L=0x0000FFFF  U=0xFFFF0000
#   k= 8  L=0x00FF00FF  U=0xFF00FF00
#   k= 4  L=0x0F0F0F0F  U=0xF0F0F0F0
#   k= 2  L=0x33333333  U=0xCCCCCCCC
#   k= 1  L=0x55555555  U=0xAAAAAAAA
# 每一步: t2 = (x & L) << k ; t3 = (x & U) >> k ; x = t2 | t3
# =============================================================================
    .globl  bitrev
bitrev:
    # ---- step 1: 交換兩個 16-bit 半字 (k = 16) ----
    # 位移 16 位不會遺失任何位元, 所以不需要遮罩, 只要 3 條指令。
    slli    t2, a0, 16          # t2 = 低 16 位 -> 高 16 位
    srli    t3, a0, 16          # t3 = 高 16 位 -> 低 16 位
    or      a0, t2, t3          # a0 = 兩個半字互換

bitrev_step8:
    # ---- step 2: 交換每個 16-bit 半字內的兩個 8-bit byte (k = 8) ----
    lui     t1, 0x00FF0         # t1 = 0x00FF0000
    addi    t1, t1, 0x0FF       # t1 = 0x00FF00FF  (L)
    xori    t0, t1, -1          # t0 = 0xFF00FF00  (U)
    and     t2, a0, t1          # t2 = 要往上移的 byte
    slli    t2, t2, 8
    and     t3, a0, t0          # t3 = 要往下移的 byte
    srli    t3, t3, 8
    or      a0, t2, t3

bitrev_step4:
    # ---- step 3: 交換每個 byte 內的兩個 4-bit nibble (k = 4) ----
    lui     t1, 0x0F0F1         # t1 = 0x0F0F1000
    addi    t1, t1, -0x0F1      # t1 = 0x0F0F0F0F  (L)
    xori    t0, t1, -1          # t0 = 0xF0F0F0F0  (U)
    and     t2, a0, t1          # t2 = 要往上移的 nibble
    slli    t2, t2, 4
    and     t3, a0, t0          # t3 = 要往下移的 nibble
    srli    t3, t3, 4
    or      a0, t2, t3

bitrev_step2:
    # ---- step 4: 交換每個 nibble 內的兩個 2-bit 群組 (k = 2) ----
    lui     t1, 0x33333         # t1 = 0x33333000
    addi    t1, t1, 0x333       # t1 = 0x33333333  (L)
    xori    t0, t1, -1          # t0 = 0xCCCCCCCC  (U)
    and     t2, a0, t1          # t2 = 要往上移的 2-bit 群組
    slli    t2, t2, 2
    and     t3, a0, t0          # t3 = 要往下移的 2-bit 群組
    srli    t3, t3, 2
    or      a0, t2, t3

bitrev_step1:
    # ---- step 5: 交換相鄰的兩個單一位元 (k = 1) ----
    lui     t1, 0x55555         # t1 = 0x55555000
    addi    t1, t1, 0x555       # t1 = 0x55555555  (L)
    xori    t0, t1, -1          # t0 = 0xAAAAAAAA  (U)
    and     t2, a0, t1          # t2 = 要往上移的位元
    slli    t2, t2, 1
    and     t3, a0, t0          # t3 = 要往下移的位元
    srli    t3, t3, 1
    or      a0, t2, t3

    ret

# =============================================================================
# [2] 測試 harness (Ripes 專用)
# -----------------------------------------------------------------------------
# 跑 CP1 (src/c_baseline/test_vectors.h) 的全部 11 組測資, 逐一比較
# 預期值與實際值, 並印出 PASS/FAIL。
#
# Ripes 的 ecall 編號 (與 Linux 不同, 僅在 Ripes 內有效):
#     a7 = 1   print_int      a0 = 整數
#     a7 = 4   print_string   a0 = 字串指標
#     a7 = 11  print_char     a0 = ASCII 字元
#     a7 = 10  exit           停止模擬器
#
# Ripes 組譯器/模擬器的兩個小限制 (本檔已避開):
#   1) .string 內的 \n 不會被當跳脫字元, 會被組出 NUL(0x00) -> 換行改用
#      print_char(0x0A), 見 print_nl。
#   2) print_string (a7=4) 會連字串結尾的 NUL 一起印出 -> 改用自寫的
#      print_str, 逐字元用 print_char 送出, 遇到 NUL 就停且不印。
#
# 測試結果同時寫入記憶體, 方便在 Ripes 的 Memory 視窗檢查:
#     results[]        : 每組測資的實際輸出
#     flags[]          : 每組測資的結果 (1 = PASS, 0 = FAIL)
#     summary_pass     : PASS 組數
#     summary_fail     : FAIL 組數
#
# harness 的暫存器配置 (測試用, 與 bitrev 函式無關):
#   s0  目前測資 (input, expected) 的位址
#   s1  測資總數 (11)
#   s2  測資索引 (0-based)
#   s3  PASS 計數
#   s4  FAIL 計數
#   s5  results[] 寫入游標
#   s6  flags[] 寫入游標
#   s7  print_hex32 的位數計數
#   s8  print_hex32 的位移量
#   s9  print_hex32 的原值 / print_str 的掃描游標
#   t1  print_str 讀出的字元
#   t6  本輪的實際輸出
# =============================================================================
    .globl  test_main
test_main:
    la      s0, vectors         # s0 = 測資表基底
    li      s1, 11              # s1 = 測資組數
    li      s2, 0               # s2 = 索引
    li      s3, 0               # s3 = PASS 數
    li      s4, 0               # s4 = FAIL 數
    la      s5, results         # s5 = results 寫入游標
    la      s6, flags           # s6 = flags 寫入游標

test_loop:
    # ---- 印出 "T<no> in=0x<input> exp=0x<expected>" ----
    la      a0, str_T
    call    print_str
    addi    a0, s2, 1           # 編號由 1 開始
    li      a7, 1
    ecall
    la      a0, str_in
    call    print_str
    lw      a0, 0(s0)           # input
    call    print_hex32
    la      a0, str_exp
    call    print_str
    lw      a0, 4(s0)           # expected
    call    print_hex32

    # ---- 呼叫 bitrev 計算實際輸出 ----
    lw      a0, 0(s0)
    call    bitrev
    mv      t6, a0              # t6 = 實際輸出
    sw      t6, 0(s5)           # 存入 results[]
    addi    s5, s5, 4

    # ---- 印出 " act=0x<actual>" ----
    la      a0, str_act
    call    print_str
    mv      a0, t6
    call    print_hex32

    # ---- 比較實際值與預期值 ----
    lw      a1, 4(s0)           # expected
    beq     t6, a1, test_pass
    # ---- FAIL ----
    addi    s4, s4, 1
    li      t0, 0
    sw      t0, 0(s6)           # flags[] = 0
    addi    s6, s6, 4
    la      a0, str_fail
    call    print_str
    call    print_nl
    j       test_next

test_pass:
    addi    s3, s3, 1
    li      t0, 1
    sw      t0, 0(s6)           # flags[] = 1
    addi    s6, s6, 4
    la      a0, str_pass
    call    print_str
    call    print_nl

test_next:
    addi    s0, s0, 8           # 下一組測資 (2 個 word)
    addi    s2, s2, 1
    blt     s2, s1, test_loop

    # ---- 印出總結 ----
    la      a0, str_done
    call    print_str
    mv      a0, s3
    li      a7, 1
    ecall
    la      a0, str_failed
    call    print_str
    mv      a0, s4
    li      a7, 1
    ecall
    call    print_nl

    # ---- 總結寫入記憶體, 方便在 Ripes Memory 視窗檢查 ----
    la      t0, summary_pass
    sw      s3, 0(t0)
    la      t0, summary_fail
    sw      s4, 0(t0)

    # ---- 結束模擬 ----
    li      a7, 10
    li      a0, 0
    ecall

# -----------------------------------------------------------------------------
# print_hex32 — 把 a0 的值印成 8 位大寫十六進位 (不含 "0x" 前綴)
# 破壞 a0/t2/t3/s7/s8, 其餘暫存器不動
# -----------------------------------------------------------------------------
    .globl  print_hex32
print_hex32:
    mv      s9, a0              # 保留原值 (print_char 會改寫 a0)
    li      s7, 8               # 還要印幾個 nibble
    li      s8, 28              # 目前的位移量
ph_loop:
    srl     t2, s9, s8          # 取出該 nibble
    andi    t2, t2, 0xF
    li      t3, 10
    blt     t2, t3, ph_dec
    addi    t2, t2, 55          # 'A'(65) - 10
    j       ph_emit
ph_dec:
    addi    t2, t2, 48          # '0'(48)
ph_emit:
    mv      a0, t2
    li      a7, 11              # print_char
    ecall
    addi    s7, s7, -1
    addi    s8, s8, -4
    bnez    s7, ph_loop
    ret

# -----------------------------------------------------------------------------
# print_str — 印出以 NUL 結尾的字串
# 註: Ripes 的 print_string (a7=4) 會把字串結尾的 NUL 也一併印出, console 會
#     出現雜訊, 因此改成自行逐字元用 print_char 送出, 讀到 NUL 就停 (不印)。
# 介面: a0 = 字串指標   破壞 a0/a7/s9/t1
# -----------------------------------------------------------------------------
    .globl  print_str
print_str:
    mv      s9, a0              # s9 = 目前掃描的位置
ps_loop:
    lbu     t1, 0(s9)           # 取出一個字元
    beq     t1, zero, ps_end    # 遇到 NUL 就結束 (NUL 不印出)
    addi    s9, s9, 1
    mv      a0, t1
    li      a7, 11              # print_char
    ecall
    j       ps_loop
ps_end:
    ret

# -----------------------------------------------------------------------------
# print_nl — 印出一個換行
# 註: Ripes 的組譯器不處理 .string 內的 \n 跳脫字元 (會被組出 NUL 0x00),
#     所以換行一律用 print_char(0x0A) 送出, 讓 console 輸出可以正常斷行。
# 破壞 a0/a7
# -----------------------------------------------------------------------------
    .globl  print_nl
print_nl:
    li      a0, 10              # 0x0A = LF
    li      a7, 11              # print_char
    ecall
    ret

# =============================================================================
# 資料區
# =============================================================================
    .data
    .align  2

# CP1 (src/c_baseline/test_vectors.h) 的 11 組測資: input, expected
vectors:
    .word   0x00000001          # 1  邊界: LSB -> MSB
    .word   0x80000000
    .word   0x0000000F          # 2  低 nibble -> 高 nibble
    .word   0xF0000000
    .word   0x12345678          # 3  題目指定範例
    .word   0x1E6A2C48
    .word   0x00000000          # 4  邊界: 全零
    .word   0x00000000
    .word   0xFFFFFFFF          # 5  邊界: 全一
    .word   0xFFFFFFFF
    .word   0x80000000          # 6  邊界: MSB -> LSB
    .word   0x00000001
    .word   0x0000FFFF          # 7  交換左右兩個 16-bit 區塊
    .word   0xFFFF0000
    .word   0x00FF00FF          # 8  交錯 byte 圖樣
    .word   0xFF00FF00
    .word   0xAAAA5555          # 9  對稱位元圖樣
    .word   0xAAAA5555
    .word   0xDEADBEEF          # 10 隨機測試值
    .word   0xF77DB57B
    .word   0xF0F0F0F0          # 11 nibble 圖樣
    .word   0x0F0F0F0F

    .align  2
results:                         # 每組測資的實際輸出 (11 words)
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
flags:                           # 每組測資的結果 1=PASS 0=FAIL (11 words)
    .word   0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
summary_pass:                    # PASS 組數
    .word   0
summary_fail:                    # FAIL 組數
    .word   0

str_T:       .string "T"
str_in:      .string " in=0x"
str_exp:     .string " exp=0x"
str_act:     .string " act=0x"
str_pass:     .string " PASS"
str_fail:     .string " FAIL"
str_done:    .string "PASSED="
str_failed:  .string " FAILED="
