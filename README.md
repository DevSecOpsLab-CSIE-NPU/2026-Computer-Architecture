# Computer Architecture 2026 — Custom RISC-V Instruction 學期專題

本倉庫為 2026 學年度第一學期《計算機組織》課程的學期專題資料。每組自組 4 人,選擇一條 **Custom RISC-V Instruction**,完成從 C baseline 到 5 級 Pipeline 的分析。

> 核心問題:如果 RISC-V CPU 要加入這條新指令,CPU 裡面需要增加或修改什麼?

## 文件導覽

| 文件 | 內容 |
|---|---|
| [HOMEWORK.md](HOMEWORK.md) | 作業說明:分組規則、選題、指令格式、繳交與報告規範、題目語意規格 |
| `mac_demo/` | 教師示範題 `MAC` 的編碼、C 參考實作、5 級 pipeline 模型與時序圖 |
| [`top2_4_demo/`](top2_4_demo/) | 示範題 `TOP2_4` 的編碼、C 參考實作、比較網路、測試與指令數 benchmark |

學生相關的規定以 [HOMEWORK.md](HOMEWORK.md) 為準。

## 目前進度

- **期中前**:C baseline、RV32IM 實作、指令規格與編碼(CP1–CP3)
- **期中後**:Datapath、Control、5 級 Pipeline、Hazard 與 Forwarding(CP4–CP6,尚未教授,規範待補)

## 分組與選題

- 分組方式:學生自組,每組固定 **4 人**
- 分組名單截止:**2026/10/09(週五)前**寄送助教,未繳交者不計作業分數
- 選題方式:**先到先得**,每組一題,每題僅允許一組選取
- 分組確定後不可更動

### 學生可選題目(19 題)

| 類別 | 題目 |
|---|---|
| 基礎運算類(7 題) | `ABS`、`MIN`、`AVG`、`CLAMP`、`ABSDIFF`、`THRESHOLD`、`MAXPIX` |
| AI / 電腦視覺類(5 題) | `ReLU6`、`Leaky_ReLU`、`CLIP`、`POPCOUNT`、`SAD` |
| 網路類(2 題) | `NETMASK`、`CSUM16` |
| 密碼學 / 雜湊類(1 題) | `ROTL` |
| DSP 類(2 題) | `ADDSAT`、`BITREV` |
| 字串 / 資料處理類(1 題) | `FINDZERO` |
| 算術類(1 題) | `CLZ` |

各題的正式語意定義見 [HOMEWORK.md 第六節](HOMEWORK.md#六題目語意規格)。

### 示範題(不開放選題)

| 題目 | 負責 | 用途 |
|---|---|---|
| `MAC`(乘加) | 教師 / 助教 | Week 7 課堂示範 |
| [`TOP2_4`](top2_4_demo/)(4×INT8 找最大與第二大) | 進階學長 | 展示 packed data 與比較網路的設計深度 |

#### MAC
![img](mac_demo/mac_demo_v4/figures/ablation.png)

#### TOP2_4

[`top2_4_demo/`](top2_4_demo/) 提供 `top2_4` 的 R-type 編碼、C baseline、RISC-V 內嵌組語、黃金模型、測試與指令數 benchmark。`top2_4` 將 `rs1` 的四個有號 INT8 lane 排序後,把最大值與第二大值寫入 `rd[7:0]` 與 `rd[15:8]`;整合編碼為 `funct3=110`、`funct7=0000000`、opcode `0001011`。

## 統一指令格式

所有自訂指令採用 R-type,操作碼為 custom-0(`0001011`,0x0B)。`funct3`、`funct7` 由教師統一分配:

```
31      25 24   20 19   15 14  12 11    7 6       0
+----------+-------+-------+------+-------+---------+
|  funct7  |  rs2  |  rs1  |funct3|  rd   | 0001011 |
+----------+-------+-------+------+-------+---------+
```

## 行事曆

| 週次 / 日期 | 課程主題 | 專題 Checkpoint |
|---|---|---|
| W1 · 09/08 | 課程說明、題目池與組隊規則公告 | — |
| W2–W4 | 學生自行組隊 | — |
| W5 · 10/06 | Instruction Format / Machine Code | HW2 發布、選題表單開放 |
| 10/09(五) | — | **分組名單寄送助教截止** |
| W6 · 10/13 | Compiler / Assembler 流程 | CP1 C baseline |
| W7 · 10/20 | Computer Arithmetic、MAC Demo | CP2 RV32IM 實作 |
| W8 · 10/27(停課,自主學習) | 期中整合 | **CP3 書面報告繳交**(指令規格、編碼、指令數比較) |
| W9 · 11/03 | **期中考**(涵蓋 W1–8) | — |
| W10 · 11/10 | Processor Datapath | CP4 開始(期中後,規範待補) |
| W11 · 11/17 | Single-Cycle Processor 與 Control | — |
| W12 · 11/24(停課,小組討論) | Datapath 整合 | CP4 繳交(規範待補) |
| W13 · 12/01 | Pipeline 基礎 | CP5(規範待補) |
| W14 · 12/08 | Pipeline Hazard | CP6 開始(規範待補) |
| W15 · 12/15 | Forwarding / Stall / Bubble | CP6 繳交(規範待補) |
| W16 · 12/22 | 整合:ISA → Pipeline | 期末成果展示(隨機抽問,組內皆須理解) |
| W17 · 12/29 | 全學期回顧 | — |
| W18 · 01/05 | 期末考 | 筆試,不含專題展示 |

**助教加課時段(正課,全班出席並點名)**:每週三 18:00–19:00,10/07、10/14、10/21。地點待助教公告。

## Pipeline 說明模板(期中後)

每組需在 5 級 pipeline 中標示自己指令在各 stage 的工作:

```
 IF        ID          EX          MEM       WB
 │         │           │           │         │
Fetch   Decode     自訂指令執行    (是否使用)  Writeback
        (讀 rs1/rs2)  在這裡嗎?
```

必須回答:

1. 原本 ALU 能否在 EX 一次完成?
2. 若運算複雜(如 Comparator / Adder Tree),是否需拆成多個 stage,對 Clock Cycle Time 的影響為何?
3. 是否使用 MEM stage?
4. `rd` 在哪個 stage 寫回 Register File?
5. Control Unit 需新增哪些控制訊號?
6. 指令的 combinational path 是否會成為全 CPU 的 Critical Path?

## 評估重點

以 **Instruction Count × CPI × Clock Cycle Time** 為主要量化框架,比較標準 RV32IM 與自訂指令。不要求真實硬體 benchmark,重點在於看懂並說明。

## 環境建置說明

學生需要的工具依進度逐步使用,不需要一次全部安裝。請依自己的電腦選擇對應的平台說明。

| 電腦 | 對應章節 |
|---|---|
| Windows(任何版本的 Windows 10/11) | 二之一 |
| MacBook Apple Silicon(M1 / M2 / M3 / M4 等) | 二之二 |
| MacBook Intel(x86_64) | 二之三 |

### 一、必要工具(Week 2 前完成)

| 工具 | 用途 | 最晚需要 |
|---|---|---|
| Git | 繳交倉庫、版本紀錄 | W2 |
| Python 3.10 以上 | 編碼與黃金模型練習 | W5 |
| RISC-V GNU 工具鏈(`riscv64-elf-gcc`) | 將 C 編譯為 RISC-V 組合語言 | W6 |
| Ripes(RISC-V 模擬器,含 5 級 pipeline 視覺化) | 執行與觀察 RV32IM 程式 | W6 |

### 二之一、Windows(使用 WSL2)

Windows 上的 RISC-V 工具鏈以 Linux 環境安裝最穩定,因此建議使用 WSL2。

**1. 安裝 WSL2 與 Ubuntu**

以系統管理員身分開啟 PowerShell,執行:

```powershell
wsl --install -d Ubuntu
```

重新開機後,依提示建立 Ubuntu 的使用者名稱與密碼。

**2. 在 Ubuntu 中安裝工具**

```bash
sudo apt update
sudo apt install -y git python3 python3-pip gcc-riscv64-unknown-elf
```

若 `gcc-riscv64-unknown-elf` 找不到,先執行 `apt search riscv64` 確認套件名稱,並告知助教。

**3. 安裝 Ripes(Windows 原生版)**

- 至官方 GitHub Releases 下載 Windows 安裝檔
- Ripes 為圖形介面程式,安裝於 Windows 即可,不需在 WSL 中執行

**4. 驗證**

在 Ubuntu 終端機執行:

```bash
git --version
python3 --version
riscv64-elf-gcc --version
```

### 二之二、MacBook Apple Silicon(arm64)

Apple Silicon 機型請使用 `/opt/homebrew` 路徑下的 Homebrew。

**1. 安裝 Homebrew**(若尚未安裝)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

安裝完成後,依終端機顯示的指示,將 `/opt/homebrew/bin` 加入 `PATH`。

**2. 安裝工具**

```bash
brew install git python riscv64-elf-gcc
```

**3. 安裝 Ripes**

- 至官方 GitHub Releases 下載 **arm64**(Apple Silicon)版本的 `.dmg`
- 若 macOS 顯示無法驗證開發者,請至「系統設定 → 隱私權與安全性」允許開啟

**4. 驗證**

```bash
git --version
python3 --version
riscv64-elf-gcc --version
```

### 二之三、MacBook Intel(x86_64)

Intel 機型的 Homebrew 位於 `/usr/local`,安裝指令與 Apple Silicon 相同,但路徑不同。

**1. 安裝 Homebrew**(若尚未安裝)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**2. 安裝工具**

```bash
brew install git python riscv64-elf-gcc
```

**3. 安裝 Ripes**

- 至官方 GitHub Releases 下載 **x86_64(Intel)**版本的 `.dmg`
- 注意不要下載到 arm64 版本,否則無法開啟

**4. 驗證**

```bash
git --version
python3 --version
riscv64-elf-gcc --version
```

### 三、各平台共同注意事項

- **Apple 內建的 `clang` 不包含 RISC-V 後端**,無法用來編譯本課程的程式,請一律使用 `riscv64-elf-gcc`
- 編譯指令請使用 `-march=rv32im -mabi=ilp32`
- 若 `riscv64-elf-gcc: command not found`,請確認已重新開啟終端機,並檢查 `PATH` 設定
- 若安裝失敗,請於課程討論區提問,附上完整錯誤訊息、作業系統版本與晶片型號(Apple Silicon 或 Intel)

### 四、第一次練習(建議於 W5 前完成)

1. 用 `git clone` 下載本組的倉庫。
2. 寫一個 C 函式,用 `riscv64-elf-gcc -S -march=rv32im -mabi=ilp32` 產生組合語言,觀察輸出。
3. 在 Ripes 中載入組合語言並執行,確認暫存器與記憶體的變化。

### 五、選用工具

- **Spike**(RISC-V ISA 模擬器):適合想要計算動態指令數的進階學生。建置步驟由教師另行提供,不屬於必要範圍。

---

## 聯絡

- 作業與公告以課程平台為準
- 分組與選題問題請於 2026/10/09 前洽授課教師或助教
