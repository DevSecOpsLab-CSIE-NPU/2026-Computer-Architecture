import unittest

from benchmark.top2_4_bench import (
    BASELINE_CORE_INSNS,
    BASELINE_PER_WORD,
    CUSTOM_CORE_INSNS,
    CUSTOM_PER_WORD,
    run_all,
    run_case,
    to_markdown,
)


class Top24BenchTest(unittest.TestCase):
    def test_per_word_counts(self):
        self.assertEqual(BASELINE_CORE_INSNS, 30)
        self.assertEqual(CUSTOM_CORE_INSNS, 1)
        self.assertEqual(BASELINE_PER_WORD, 34)
        self.assertEqual(CUSTOM_PER_WORD, 5)

    def test_n_64_same_clock(self):
        row = run_case(64, 1.0)
        self.assertEqual(row["standard_ic"], 2176)
        self.assertEqual(row["custom_ic"], 320)
        self.assertAlmostEqual(row["ic_reduction_pct"], 85.29411764705883)
        self.assertAlmostEqual(row["speedup"], 6.8)

    def test_n_1024_same_clock(self):
        row = run_case(1024, 1.0)
        self.assertEqual(row["standard_ic"], 34816)
        self.assertEqual(row["custom_ic"], 5120)
        self.assertAlmostEqual(row["speedup"], 6.8)

    def test_clock_sensitivity(self):
        self.assertAlmostEqual(run_case(1024, 1.2)["speedup"], 6.8 / 1.2)
        self.assertAlmostEqual(run_case(1024, 2.0)["speedup"], 3.4)
        self.assertAlmostEqual(run_case(1024, 3.0)["speedup"], 6.8 / 3.0)

    def test_run_all_shape(self):
        rows = run_all(ns=(64, 256), ratios=(1.0, 2.0))
        self.assertEqual(len(rows), 4)
        self.assertEqual(rows[0]["n"], 64)
        self.assertEqual(rows[-1]["n"], 256)

    def test_markdown_header(self):
        text = to_markdown(run_all(ns=(64,), ratios=(1.0,)))
        self.assertIn("RV32IM IC", text)
        self.assertIn("TOP2_4 IC", text)
        self.assertIn("6.80x", text)


if __name__ == "__main__":
    unittest.main()
