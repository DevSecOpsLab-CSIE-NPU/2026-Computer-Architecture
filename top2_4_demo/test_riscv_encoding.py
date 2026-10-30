import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from top2_4_encoding import decode_top2_4


ROOT = Path(__file__).resolve().parent
RV_GCC = shutil.which("riscv64-elf-gcc")
RV_OBJDUMP = shutil.which("riscv64-elf-objdump")


@unittest.skipUnless(RV_GCC and RV_OBJDUMP, "RISC-V toolchain not installed")
class RiscvEncodingTest(unittest.TestCase):
    def test_probe_assembles_to_top2_4(self):
        with tempfile.TemporaryDirectory() as tmp:
            obj = Path(tmp) / "probe.o"
            subprocess.run(
                [
                    RV_GCC,
                    "-march=rv32im",
                    "-mabi=ilp32",
                    "-O2",
                    "-c",
                    str(ROOT / "riscv_probe.c"),
                    "-o",
                    str(obj),
                ],
                check=True,
                capture_output=True,
                text=True,
            )
            text = subprocess.run(
                [RV_OBJDUMP, "-d", str(obj)],
                check=True,
                capture_output=True,
                text=True,
            ).stdout

        words = []
        for line in text.splitlines():
            if ".insn" in line:
                words.append(int(line.split()[1], 16))
        self.assertTrue(words)
        decoded = decode_top2_4(words[0])
        self.assertIsNotNone(decoded)
        self.assertEqual(decoded[2], 0)


if __name__ == "__main__":
    unittest.main()
