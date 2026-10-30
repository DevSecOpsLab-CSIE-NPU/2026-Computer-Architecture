# 期中前(CP1–CP3)各指令效率與設計彙整

> 資料截止:2026-10-30
> 資料來源:本倉庫 GitHub PR #1–#34 與各組 CP2／CP3 報告
> 定義:本表所稱「效率提升」為**指令數減少率(IC reduction)**,計算式為
> `(baseline − 自訂) ÷ baseline × 100%`。這不是執行時間、CPI 或 clock cycle
> 的加速比;依 HOMEWORK.md §5.4,CP3 不要求 cycle 數,pipeline 相關分析待 CP4–CP6。
> 第二節整理各組 instruction 的語意、編碼與設計重點。

## 一、總表

| 題目 | 組別／學號(PR) | 基準寫法 | 靜態 baseline → 自訂 | 靜態減少 | 動態 baseline → 自訂 | 動態減少 | 計數方法 | 資料狀態 |
|---|---|---|---|---:|---|---:|---|---|
| CLZ | 1114405003 等(PR #31) | 分段檢查 16／8／4／2／1 | 25 → 1 | 96.0% | 3–23 → 1 | 66.7–95.7% | Python RV32I trace;QEMU 驗證 baseline | CP3 完成(PR open) |
| BITREV | 1114405020 等(PR #33) | 五階段遮罩交換 | 36 → 2(函式)／1(內嵌) | 94.4%／97.2% | 36 → 2／1(設計推算) | 94.4%／97.2% | objdump 靜態計數;動態為設計推算 | CP3 完成;CPU 未實測 |
| ROTL(單次) | 1114405055(PR #21) | GCC -O2 變數旋轉／手寫無分支／常數旋轉 | 5／4／3 → 1(不含 call／ret) | 80.0%／75.0%／66.7% | 同靜態(固定路徑) | 同靜態 | 自製 Python RV32IM 模擬器 | CP3 部分完成(3.6、4、5、AI 待填) |
| ROTL(實際程式) | 1114405055(PR #21) | ChaCha20／RC5 setup／RC5 encrypt | 236→177／62→57／29→21 | 25.0%／8.1%／27.6% | 1919→1284／2467→2000／227→131 | 33.1%／18.9%／42.3% | 同上 | 同上 |
| THRESHOLD | 第06組(PR #26、#12) | 有號 `bge` 分支 | 5 → 2(含 `ret`) | 60.0% | 3 → 2(含 `ret`) | 33.3% | Ripes v2.3.0(RV32_SS、RV32IM) | CP3 草稿;自訂為 `threshold`+`ret` |
| ABSDIFF | 1114405017(PR #32) | `sub` + `bge` + 條件 `sub` | 3 → 1;含 `ret` 4 → 1 | 66.7%;75.0% | 2–3 → 1;含 `ret` 3–4 → 1 | 50.0–66.7%;66.7–75.0% | 靜態與路徑計數;未執行自訂指令 | CP3 完成;`funct3`／`funct7` 待確認 |
| SAD | 1114405036(PR #18、#34) | `slt` + 2×`sub` + `beq` + 2×`add` | 6 → 1;含 `ret` 7 → 1 | 83.3%;85.7% | 5–6 → 1;含 `ret` 6–7 → 1 | 80.0–83.3%;83.3–85.7% | 人工逐條計數 | 僅 CP2 + CP3 編碼片段 |
| MIN | Edwin-Tu(PR #25) | branch 3／C baseline 4／branchless 6 | 3／4／6 → 1 | 66.7%／75.0%／83.3% | 38／46／84 → 14(14 組測資) | 63.2%／69.6%／83.3% | Python RV32I 直譯器 | 僅 CP2 |
| ABS | 1111410057(PR #23) | `srai` + `xor` + `sub` + `ret` | 4 → 1;核心 3 → 1 | 75.0%;66.7% | 40 → 10;核心 30 → 10(10 組測資) | 75.0%;66.7% | Ripes 5-stage | 僅 CP2 |
| CLIP | 1113405016(PR #1) | `li` + `bge` + `blt` 分支 | 12 → 1 | 91.7% | 4–6 → 1 | 75.0–83.3% | Ripes | 僅 CP2 |

> 註 1:「自訂」欄除 BITREV 另列函式／內嵌、THRESHOLD 另列 `threshold`+`ret`
> 外,均以單條自訂指令計。各列以該組報告的計數範圍為準;有標示 `ret` 者依
> 標示,未標示者表示該組未區分 `ret`。不同組的計數範圍不完全一致,跨題比較
> 時請以「同一列內的 baseline 與自訂」為準,不要直接把不同題目的百分比排名。
>
> 註 2:MIN、ABS、CLIP 尚未提交 CP3,「自訂 = 1」是假設每呼叫一條自訂指令的
> 推算值,不是已量測的自訂指令執行結果。
>
> 註 3:THRESHOLD 的 CP3 草稿把自訂指令寫成 `threshold` + `ret` 共 2 條,
> 因此以 5→2、3→2 計;若只算 `threshold` 單條,則為 5→1(80.0%)、
> 3→1(66.7%),但這不是該組 CP3 的正式比較。

## 二、各組 instruction 設計內容

### 2.1 共同編碼格式

所有已提交 CP3 的自訂指令都採 R-type、custom-0,欄位如下:

```text
31      25 24   20 19   15 14  12 11    7 6       0
+----------+-------+-------+------+-------+---------+
|  funct7  |  rs2  |  rs1  |funct3|  rd   | 0001011 |
+----------+-------+-------+------+-------+---------+
```

`opcode = 0001011`(0x0B)。目前多數組別採 `funct3=000`、`funct7=0000000`;
這代表**同一顆 CPU 只能選一條實作**,若要多條並存,必須重新分配
`funct3`／`funct7`。ABSDIFF 的 funct 仍是提案,SAD 只定欄位,
MIN／ABS／CLIP 尚無 CP3 編碼。

### 2.2 設計總表

同一內容的機器可讀版見 [`instruction_design.csv`](instruction_design.csv)。

| 題目(PR) | 語意(公式) | 運算元／結果 | 設計重點 | 機器碼範例 | 狀態 |
|---|---|---|---|---|---|
| CLZ(PR #31) | `rd = 32 − bit_length(rs1)`;`bit_length(0)=0` | `rs1` 輸入;`rs2` 不使用;`rd` 為 0–32 | 單條位元掃描;baseline 分段檢查 16／8／4／2／1;`rd=x0` 不寫回 | `clz x10,x11` = `0x0005850B` | CP3 完成 |
| BITREV(PR #33) | `rd[i] = rs1[31−i]` | `rs1` 輸入;`rs2` 不使用;`rd` 為位元反轉結果 | 運算本身幾乎只是接線,不需 ALU/MUX;baseline 用五階段遮罩交換 | `bitrev a0,a0` = `0x0005050B` | CP3 完成 |
| ROTL(PR #21) | `n = rs2[4:0]`;`rd = (n==0) ? rs1 : (rs1<<n) OR (rs1>>(32−n))` | `rs1` 為值;`rs2` 為移位量(低 5 位);`rd` 為結果 | 桶型移位器;`n=0` 邊界;與 Zbb `rol` 語意相同但編碼不同 | `rotl a0,a1,a2` = `0x00C5850B` | CP3 部分完成 |
| THRESHOLD(PR #26) | `rd = (rs1 >= rs2) ? 255 : 0`(有號) | `rs1` 輸入;`rs2` 門檻;`rd` 為 0 或 255 | 有號比較;只比較不加減,不溢位;誤用無號比較會在負數邊界出錯 | `threshold a0,a0,a1` = `0x00B5050B` | CP3 草稿 |
| ABSDIFF(PR #32) | `rd = abs32((rs1 − rs2) mod 2^32)` | `rs1`、`rs2` 為有號二補數;`rd` 為 0–`0x80000000` | 先做 32-bit wrap 減法再取絕對值;`INT32_MIN` 邊界;funct 為提案 | `absdiff a0,a0,a1` = `0x00B5050B`(提案) | CP3 完成;funct 待確認 |
| SAD(PR #18、#34) | `rd = (rd + abs(rs1 − rs2)) mod 2^32` | `rs1`、`rs2` 輸入;`rd` 同時是累加器 | baseline 核心 6 條:有號 `slt` 選差值方向、2×`sub`、`beq`、2×`add`;先選大數再相減可避免差值溢位 | 待補(原始報告未列十六進位) | 僅 CP2 + CP3 編碼片段 |
| MIN(PR #25) | `rd = min(rs1, rs2)`(有號) | `rs1`、`rs2` 有號;`rd` 為較小值 | CP2 用 `blt` 分支(3 條)或 branchless 遮罩(6 條);尚無自訂編碼 | 尚無 | 僅 CP2 |
| ABS(PR #23) | `rd = abs(rs1)`(32-bit 二補數) | `rs1` 有號;`rd` 為絕對值 | CP2 無分支 `srai`+`xor`+`sub`(核心 3 條);尚無自訂編碼 | 尚無 | 僅 CP2 |
| CLIP(PR #1) | `rd = min(max(rs1, −128), 127)` | `rs1` 有號;`rd` 為裁切值 | CP2 用 `li`+`bge`+`blt` 分支(靜態 12 條);尚無自訂編碼 | 尚無 | 僅 CP2 |

### 2.3 編碼欄位對照

| 題目 | funct7 | funct3 | opcode | rs2 用途 | 備註 |
|---|---|---|---|---|---|
| CLZ | `0000000` | `000` | `0001011` | 固定 `00000` | `rs2` 不使用 |
| BITREV | `0000000` | `000` | `0001011` | 固定 `00000` | `rs2` 不使用 |
| ROTL | `0000000` | `000` | `0001011` | 移位量 | 只取低 5 位 |
| THRESHOLD | `0000000` | `000` | `0001011` | 門檻 | 有號比較 |
| ABSDIFF | `0000000`(提案) | `000`(提案) | `0001011` | 第二來源 | funct 尚未確認 |
| SAD | `0000000` | `000` | `0001011` | 第二來源 | 欄位已定,範例待補 |
| MIN | — | — | — | — | 尚無 CP3 |
| ABS | — | — | — | — | 尚無 CP3 |
| CLIP | — | — | — | — | 尚無 CP3 |

### 2.4 設計觀察

- **運算型態**:CLZ、BITREV 是單輸入(`rs2` 固定 0);ROTL、THRESHOLD、
  ABSDIFF、SAD 是雙輸入;SAD 的 `rd` 同時是累加器,屬 read-modify-write。
- **硬體成本**:BITREV 幾乎只是接線;CLZ 需要優先編碼器／位元掃描;
  ROTL 需要桶型移位器;THRESHOLD、ABSDIFF、SAD 需要比較器與加減法器。
  CP4–CP6 應把這些單元放入 EX stage,檢查 critical path。
- **編碼衝突**:多組都用 `funct3=000`、`funct7=0000000`,同一顆 CPU 只能
  支援一條;跨組比較不受影響,但整合多條時必須重新分配 funct。這是目前
  設計內容最大的共同限制。
- **未完成設計**:MIN、ABS、CLIP 只有 RV32IM 軟體實作,尚無自訂指令的欄位、
  機器碼與硬體設計;AVG、MAXPIX 只有 CP1 C baseline。

## 三、資料來源

1. **CLZ**:PR #31(open) `instructions/19_CLZ/report/CP3.md`;
   舊版 PR #27 `instructions/19_CLZ/report/CP3.md`。
2. **BITREV**:PR #33(open) `group17_BITREV/report/CP3.md`、
   `group17_BITREV/report/cp3-c/instruction-count-comparison.md`。
3. **ROTL**:PR #21 `instructions/15_ROTL/report/CP3.md`;
   原始量測 `instructions/15_ROTL/report/figures/instruction_counts.md`。
4. **THRESHOLD**:PR #26 `instructions/06_THRESHOLD/rv32im/count_result.md`;
   CP3 草稿見 PR #12、#13、#26 的 `report/CP3.md`。
5. **ABSDIFF**:PR #32 `report/CP3.md`。
6. **SAD**:PR #18 `instructions/12_SAD/report/CP2.md`、
   `instructions/12_SAD/rv32im/README.md`;PR #34 `instructions/12_SAD/spec/encoding.md`。
7. **MIN**:PR #25 `instructions/02_MIN/report/CP2.md`、
   `instructions/02_MIN/references/measurements.md`。
8. **ABS**:PR #23 `instructions/01_ABS/report/CP2.md`。
9. **CLIP**:PR #1 `report/CP2.md`。

## 四、判讀注意事項

1. **只比較指令數**:本表沒有 CPI、clock cycle time、執行時間或真實硬體數據。
   指令數減少不等於同比例加速,因為自訂指令的 combinational path 可能較長。
2. **靜態與動態不同**:靜態是程式碼中的指令位置數;動態是實際執行經過的
   指令數。有分支的 baseline(MIN、ABSDIFF、SAD、THRESHOLD、CLIP)會因輸入
   走不同路徑,動態數是一個範圍。
3. **`ret` 計數不一致**:部分組別把 `ret` 計入函式成本,部分組別只算運算本體。
   本表盡量同時列出兩種數字;若只有一個數字,則以該組報告的定義為準。
4. **證據等級不同**:
   - CLZ、ROTL 有可重跑的模擬器或 trace 工具。
   - BITREV 的動態數是設計推算,沒有自訂 CPU 執行證據。
   - ABSDIFF 的 `funct3`／`funct7` 尚未確認,機器碼是提案。
   - THRESHOLD 的 CP3 仍是草稿(自訂 2 條與迴圈估計來自草稿);SAD 只有 CP2
     加上 CP3 編碼片段。
   - MIN、ABS、CLIP 只有 CP2,沒有 CP3 規格與編碼。
5. **Amdahl 定律**:單次運算的減少率通常很高(例如 ROTL 單次 66.7–80.0%),
   但放進完整程式後,實際減少的比例取決於該運算佔全部指令的比例
   (ROTL 的 ChaCha20／RC5 實測只有 18.9–42.3%)。

## 五、尚未有指令數數據的題目

| 題目 | 現有資料 | 說明 |
|---|---|---|
| AVG | PR #6(僅 CP1) | 只有 C baseline,尚無 RV32IM 指令統計或 CP3 |
| MAXPIX | PR #11(僅 CP1) | 只有 C baseline 與測試向量,尚無指令數比較 |
| CLAMP | 無 PR | 本倉庫目前沒有該題的提交 |
| ReLU6 | 無 PR | 本倉庫目前沒有該題的提交 |
| Leaky_ReLU | 無 PR | 本倉庫目前沒有該題的提交 |
| POPCOUNT | 無 PR | 本倉庫目前沒有該題的提交 |
| NETMASK | 無 PR | 本倉庫目前沒有該題的提交 |
| CSUM16 | 無 PR | 本倉庫目前沒有該題的提交 |
| ADDSAT | 無 PR | 本倉庫目前沒有該題的提交 |
| FINDZERO | 無 PR | 本倉庫目前沒有該題的提交 |

## 六、THRESHOLD 迴圈工作負載(CP3 模型估計)

PR #12 的 CP3 草稿另外用模型估計把 THRESHOLD 放進迴圈後的動態指令數;
這不是 Ripes 量測自訂指令,而是假設自訂指令存在後的估算:

| 工作負載 | RV32IM 分支版 | THRESHOLD | 指令數減少 | CPI=1 時加速比 |
|---|---:|---:|---:|---:|
| N=8,門檻 5 | 77 | 64 | 16.9% | 1.20× |
| N=1024,像素 0–255,門檻 128 | 8693 | 7176 | 17.5% | 1.21× |
| 同上,自訂指令使時脈週期慢 20% | 8693 | 7176 | 17.5% | 1.01× |

最後一列說明:若自訂指令的 combinational path 讓 clock cycle time 增加 20%,
原本 1.21× 的指令數優勢會被抵銷到約 1.01×。這是本表唯一有「指令數以外」
敏感度分析的題目,但仍不是實際量測。

## 七、摘要觀察

- **靜態指令數減少率較高且證據較完整**:CLZ 96.0%、BITREV 94.4–97.2%、
  ABSDIFF 66.7–75.0%。
- **實際程式動態減少率較低**:ROTL 在 ChaCha20／RC5 上為 18.9–42.3%,
  明顯低於單次旋轉的 66.7–80.0%,是 Amdahl 定律的直接例子。
- **分支型指令的絕對節省有限**:MIN、ABS、CLIP、THRESHOLD 的 baseline 只有
  3–6 條,雖然減少率高,但每次只省下 1–11 條;是否值得加入硬體,仍需看
  實際程式中該運算的出現頻率。
- **目前不宜做跨題排名**:9 題有數據,但只有 CLZ、BITREV、ROTL、ABSDIFF
  有較完整的 CP3;其餘多為 CP2 或草稿,且計數範圍、`ret` 處理與工具不同。
