# 07_MAXPIX/rv32im/

- 對應 Checkpoint:CP2
- 內容:RV32IM 組合語言實作、測試 harness 與指令數統計

`maxpix_rv32im` 採 RISC-V ILP32 函式呼叫慣例：輸入 packed pixels 放在 `a0`，結果也回傳於 `a0`。像素依低位元組到高位元組順序擷取，透過 `sltu` 做無號比較。程式只使用 RV32I 子集指令，因此符合 RV32IM。

若有支援 RV32 ILP32 Linux 的 hosted cross compiler，可用下列命令編譯並執行測試：

```sh
riscv64-linux-gnu-gcc -march=rv32im -mabi=ilp32 -O0 -static \
  maxpix.S test_maxpix_rv32im.c -o test_maxpix_rv32im
```

此命令產生 RV32 Linux ELF，需在支援該 ELF 的模擬器或目標環境執行。課程提供的 `riscv64-elf-gcc` 若為 bare-metal 工具鏈，可用 `-c maxpix.S` 單獨組譯函式；C 測試 harness 則需 hosted C library，或接入模擬器提供的測試環境。

## 指令統計

統計範圍為 `maxpix_rv32im` 函式本身，不含呼叫端、測試程式或 ELF 啟動程式。靜態指令數依 GNU assembler 對 pseudo-instruction 的展開計算：`mv` 為 `addi rd, rs, 0`，`ret` 為 `jalr x0, 0(ra)`。程式共 18 條靜態指令，其中 3 條條件分支 `beqz`；另有 1 條函式返回 `jalr`。

每次呼叫固定執行 3 條 `sltu` 與 3 條條件分支。若目前最大值小於下一個像素，會多執行一條 `mv`。因此動態指令數為 15–18 條，條件分支執行數固定為 3，條件分支 taken 數視輸入而定；以下 12 組向量的動態統計：

| 測資 | 輸入 | 更新最大值次數 | 動態指令數 | 條件分支 taken / 執行 |
|---:|---:|---:|---:|---:|
| 1 | `0x0A1E2805` | 1 | 16 | 2 / 3 |
| 2 | `0x00000000` | 0 | 15 | 3 / 3 |
| 3 | `0xFF000001` | 1 | 16 | 2 / 3 |
| 4 | `0x01020304` | 0 | 15 | 3 / 3 |
| 5 | `0x11223344` | 0 | 15 | 3 / 3 |
| 6 | `0x7F807F80` | 0 | 15 | 3 / 3 |
| 7 | `0x0100FF00` | 1 | 16 | 2 / 3 |
| 8 | `0xAAAAAAAA` | 0 | 15 | 3 / 3 |
| 9 | `0x00FF00FF` | 0 | 15 | 3 / 3 |
| 10 | `0x010101FF` | 0 | 15 | 3 / 3 |
| 11 | `0x00000001` | 0 | 15 | 3 / 3 |
| 12 | `0xFFFFFFFF` | 0 | 15 | 3 / 3 |

動態數的基本公式為 `15 + 更新最大值的次數`；每組都執行 1 條 `jalr` 返回指令。統計為依組合語言控制流程計算，並非模擬器 trace。使用的共用測資見 [`../tests/vectors.csv`](../tests/vectors.csv)。
