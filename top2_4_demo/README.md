# top2_4_demo:TOP2_4 自訂指令示範

本資料夾是示範題 `TOP2_4`(4×INT8 找最大與第二大)的完整材料:指令編碼、C 參考實作、RISC-V 內嵌組語、黃金模型、測試與指令數 benchmark。學生不得選此題,由進階學長示範 packed data 與比較網路的設計。

## 一、指令定義

```
top2_4 rd, rs1          rd = {second[7:0], max[7:0]}
```

`rs1` 視為四個有號 8-bit lane,由低到高分別是 lane 0–3:

```
rs1[7:0]    lane 0
rs1[15:8]   lane 1
rs1[23:16]  lane 2
rs1[31:24]  lane 3
```

指令找出四個 lane 的最大值 `max` 與第二大值 `second`,結果寫入 `rd`:

```
rd[7:0]   = max
rd[15:8]  = second
rd[31:16] = 0
```

- 有號比較:`0x80` 代表 −128,`0x7F` 代表 127
- 重複值允許:例如四條 lane 都是 5,則 `max = 5`、`second = 5`
- `rs2` 不使用;標準編碼填 `x0`(`rs2 = 0`)
- `rd = x0` 時結果丟棄;`rs1 = x0` 時四條 lane 都是 0

### 1.1 編碼

R-type,custom-0 opcode(`0001011`,0x0B):

| 欄位 | 值 |
|---|---|
| `funct7` | `0000000` |
| `rs2` | `00000`(忽略) |
| `rs1` | 來源暫存器 |
| `funct3` | `110` |
| `rd` | 目的暫存器 |
| `opcode` | `0001011` |

`top2_4 a0, a1`(`rd = x10`,`rs1 = x11`,`rs2 = x0`)的機器碼:

```
0x0005E50B
00000000000001011110010100001011
```

`funct3 = 110` 在目前的整合編碼規劃中屬 packed/network 類,與 `MAC`(`000`/`010`)、`THRESHOLD`(`000`)等指令不衝突。

### 1.2 使用範例

| `rs1` | lanes(低到高) | `max` | `second` | `rd` |
|---|---|---|---|---|
| `0x7F80FF01` | `1, -1, -128, 127` | 127 | 1 | `0x0000017F` |
| `0x0380FFFB` | `-5, -1, -128, 3` | 3 | −1 | `0x0000FF03` |
| `0x05050505` | `5, 5, 5, 5` | 5 | 5 | `0x00000505` |
| `0x80808080` | `-128, -128, -128, -128` | −128 | −128 | `0x00008080` |

## 二、設計內容

### 2.1 比較網路

先將四條 lane 兩兩比較:

```
(a1, b1) = sort_desc(a, b)
(c1, d1) = sort_desc(c, d)
max      = max(a1, c1)
second   = max(min(a1, c1), max(b1, d1))
```

總共 **5 個有號比較器**。`max` 與 `second` 的路徑深度約為 3 個比較器,比完整排序網路少一層。

### 2.2 硬體需求

- 4 個 INT8 → INT32 符號延伸
- 5 個有號比較器
- 5 個 2:1 MUX(或等價的選擇邏輯)
- 結果 pack:兩個 8-bit 欄位合併,高位補 0

EX stage 需要新增 `TOP2_4` 的 ALU 控制訊號;不使用 MEM stage,`rd` 在 WB 寫回。若比較器與 MUX 讓 combinational path 變長,需用 `t_ratio` 做時鐘敏感度分析。

## 三、檔案一覽

| 檔案 | 說明 |
|---|---|
| `top2_4.h` | `top2_4_insn` 內嵌組語與 `top2_4_ref` 宣告 |
| `top2_4.c` | RV32IM C baseline:5 個比較器的 top-two 網路 |
| `test_top2_4.c` | C 測試:已知值、負數、重複值、10,000 組隨機比對 |
| `top2_4_encoding.py` | 編碼、解碼、sext8、unpack、黃金模型、register 語意 |
| `test_top2_4_encoding.py` | 編碼往返、機器碼、黃金模型、`x0` 語意測試 |
| `riscv_probe.c` | 以 `.insn r 0x0b, 6, 0, ...` 產生 TOP2_4 的 RISC-V 物件 |
| `test_riscv_encoding.py` | 用 `riscv64-elf-gcc`/`objdump` 驗證機器碼(無工具鏈時跳過) |
| `benchmark/top2_4_bench.py` | 每字指令數、IC 減少量、`t_ratio` 敏感度模型 |
| `benchmark/test_top2_4_bench.py` | benchmark 計數與公式測試 |
| `benchmark/results.csv` | 15 組 N × T ratio 的模型結果 |
| `Makefile` | 測試、RISC-V 檢查與 benchmark 入口 |

## 四、執行方式

```bash
make test           # C 測試 + 24 項 Python 測試
make test-c         # 只跑 C 測試
make test-py        # 只跑 Python 測試
make check-riscv    # 交叉編譯 probe 並用 objdump 檢查機器碼
make bench          # 產生 benchmark 表格與 results.csv
make clean
```

需求:

- C11 編譯器(`cc` 或 `gcc`)
- Python 3.10 以上
- `riscv64-elf-gcc` 與 `riscv64-elf-objdump`(僅 `make check-riscv` 需要)

目前結果:**C 測試通過,24 項 Python 測試通過,RISC-V 編碼檢查通過**。

## 五、指令數比較(模型估計)

### 5.1 計數方式

`top2_4_ref` 以 `riscv64-elf-gcc 16.2.0 -march=rv32im -O2` 編譯後,函式本體為 **31 條指令(含 `ret`)**。本 benchmark 假設函式被 inlined,因此 core 採 **30 條**(不含 `ret`)。

每個 packed 32-bit word 的迴圈成本:

| 版本 | 每字指令數 | 組成 |
|---|---:|---|
| RV32IM baseline | 34 | `lw` + 30 條 top-two 本體 + 3 條迴圈控制 |
| `TOP2_4` | 5 | `lw` + 1 條 `top2_4` + 3 條迴圈控制 |

- 只看運算本體:30 → 1,減少 **96.7%**
- 放入每字迴圈:34 → 5,減少 **85.3%**
- CPI = 1、`t_ratio = 1.0` 時,模型加速比 **6.80×**

> 30 條是靜態最長路徑;baseline 的分支可能跳過部分 `mv`,所以動態 baseline 可能略少。85.3% 是偏樂觀的上界,不是 Ripes 實測。

### 5.2 結果

`N` 是 packed 32-bit word 數,`INT8 lanes = 4N`。加速比與 N 無關,因為每字成本固定。

| N (words) | INT8 lanes | T ratio | RV32IM IC | TOP2_4 IC | IC reduction | Speedup |
|---:|---:|---:|---:|---:|---:|---:|
| 64 | 256 | 1.0 | 2176 | 320 | 85.3% | 6.80× |
| 64 | 256 | 1.2 | 2176 | 320 | 85.3% | 5.67× |
| 64 | 256 | 1.5 | 2176 | 320 | 85.3% | 4.53× |
| 64 | 256 | 2.0 | 2176 | 320 | 85.3% | 3.40× |
| 64 | 256 | 3.0 | 2176 | 320 | 85.3% | 2.27× |
| 256 | 1024 | 1.0 | 8704 | 1280 | 85.3% | 6.80× |
| 256 | 1024 | 2.0 | 8704 | 1280 | 85.3% | 3.40× |
| 1024 | 4096 | 1.0 | 34816 | 5120 | 85.3% | 6.80× |
| 1024 | 4096 | 2.0 | 34816 | 5120 | 85.3% | 3.40× |
| 1024 | 4096 | 3.0 | 34816 | 5120 | 85.3% | 2.27× |

完整 15 列見 [`benchmark/results.csv`](benchmark/results.csv)。

### 5.3 判讀

- 這是指令數模型,不是 cycle 或執行時間實測。
- `TOP2_4` 的比較網路比單一 ALU 運算長;若 clock cycle time 增加 2 倍,加速比由 6.80× 降到 3.40×;增加 3 倍仍有 2.27×。
- 若 baseline 使用更強的寫法(例如先將四條 lane 載入暫存器),每字指令數會下降,加速比也會變小。報告時必須說明 baseline。

## 六、與 `before-mid-term` 表格的對應

`before-mid-term/README.md` §2.6 與 `instruction_detailed_summary.csv` 的 `TOP2_4` 列已改用本資料夾的數據:

- 編碼:`110/0000000/0001011`,`0x0005E50B`
- IC:核心 30→1(96.7%);每字迴圈 34→5(85.3%)
- 加速比:CPI=1、同頻 6.80×;clock×2 為 3.40×;clock×3 為 2.27×
- 資料來源:`top2_4_demo/`

## 七、限制

- 沒有 RTL、沒有實際 CPU 執行自訂指令、沒有 Ripes trace。
- C 測試在 host 上以 `top2_4_ref` 代替 `top2_4_insn`;RISC-V 端只驗證編碼,不驗證執行結果。
- `t_ratio` 是假設值,不是從合成或電路模擬得到。
- 5 個比較器的面積與 critical path 未估算;若要做硬體比較,需補 synthesis 或 gate-level 數據。
