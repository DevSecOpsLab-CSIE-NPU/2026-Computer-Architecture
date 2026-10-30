"""Instruction-count and clock-sensitivity model for TOP2_4.

The RV32IM baseline is the GCC 16.2.0 -O2 output of top2_4_ref: 31 instructions
including ret, so 30 instructions for the inlined operation body.  A loop that
processes one packed 32-bit word adds one load and three loop-control
instructions.  The custom version replaces the 30-instruction body with one
TOP2_4 instruction.  CPI is assumed to be 1 for both versions; t_ratio is the
custom instruction's clock-cycle time divided by the baseline clock-cycle time.
"""

import csv
from pathlib import Path

BASELINE_CORE_INSNS = 30
CUSTOM_CORE_INSNS = 1
LOAD_INSNS = 1
LOOP_OVERHEAD_INSNS = 3
BASELINE_PER_WORD = LOAD_INSNS + BASELINE_CORE_INSNS + LOOP_OVERHEAD_INSNS
CUSTOM_PER_WORD = LOAD_INSNS + CUSTOM_CORE_INSNS + LOOP_OVERHEAD_INSNS


def run_case(n: int, t_ratio: float = 1.0) -> dict:
    standard_ic = n * BASELINE_PER_WORD
    custom_ic = n * CUSTOM_PER_WORD
    reduction = (standard_ic - custom_ic) / standard_ic * 100.0
    speedup = standard_ic / (custom_ic * t_ratio)
    return {
        "n": n,
        "elements": 4 * n,
        "t_ratio": t_ratio,
        "standard_ic": standard_ic,
        "custom_ic": custom_ic,
        "ic_reduction_pct": reduction,
        "speedup": speedup,
    }


def run_all(ns=(64, 256, 1024), ratios=(1.0, 1.2, 1.5, 2.0, 3.0)):
    return [run_case(n, t) for n in ns for t in ratios]


def to_markdown(rows) -> str:
    lines = [
        "| N (words) | INT8 lanes | T ratio | RV32IM IC | TOP2_4 IC | IC reduction | Speedup |",
        "|---:|---:|---:|---:|---:|---:|---:|",
    ]
    for row in rows:
        lines.append(
            f"| {row['n']} | {row['elements']} | {row['t_ratio']:.1f} | "
            f"{row['standard_ic']} | {row['custom_ic']} | "
            f"{row['ic_reduction_pct']:.1f}% | {row['speedup']:.2f}x |"
        )
    return "\n".join(lines)


def write_csv(path: Path, rows) -> None:
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0]))
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    rows = run_all()
    print(to_markdown(rows))
    print()
    print(f"baseline per word: {BASELINE_PER_WORD} instructions")
    print(f"custom per word:   {CUSTOM_PER_WORD} instructions")
    print(f"core-only reduction: {(BASELINE_CORE_INSNS - CUSTOM_CORE_INSNS) / BASELINE_CORE_INSNS * 100:.1f}%")
    write_csv(Path(__file__).with_name("results.csv"), rows)
