import random
import unittest

from top2_4_encoding import (
    OPCODE_CUSTOM0,
    apply_top2_4,
    decode_top2_4,
    encode_top2_4,
    pack_top2,
    sext8,
    top2_4_golden,
    top2_4_values,
    unpack_int8,
)


class Top24EncodingTest(unittest.TestCase):
    def test_encode_example(self):
        self.assertEqual(encode_top2_4(10, 11), 0x0005E50B)

    def test_decode_example(self):
        self.assertEqual(decode_top2_4(0x0005E50B), (10, 11, 0))

    def test_encode_decode_round_trip(self):
        for rd in (1, 5, 10, 31):
            for rs1 in (0, 1, 11, 31):
                word = encode_top2_4(rd, rs1)
                self.assertEqual(decode_top2_4(word), (rd, rs1, 0))

    def test_rejects_wrong_opcode(self):
        word = encode_top2_4(10, 11)
        self.assertIsNone(decode_top2_4(word ^ 0x01))

    def test_rejects_wrong_funct3(self):
        word = encode_top2_4(10, 11)
        self.assertIsNone(decode_top2_4(word ^ (1 << 12)))

    def test_rejects_wrong_funct7(self):
        word = encode_top2_4(10, 11)
        self.assertIsNone(decode_top2_4(word ^ (1 << 25)))

    def test_register_range(self):
        for bad in (-1, 32):
            with self.assertRaises(ValueError):
                encode_top2_4(bad, 0)
            with self.assertRaises(ValueError):
                encode_top2_4(0, bad)
            with self.assertRaises(ValueError):
                encode_top2_4(0, 0, bad)

    def test_sext8(self):
        self.assertEqual(sext8(0x00), 0)
        self.assertEqual(sext8(0x7F), 127)
        self.assertEqual(sext8(0x80), -128)
        self.assertEqual(sext8(0xFF), -1)

    def test_unpack_little_endian_lanes(self):
        self.assertEqual(unpack_int8(0x7F80FF01), (1, -1, -128, 127))

    def test_pack_top2(self):
        self.assertEqual(pack_top2(127, 1), 0x017F)
        self.assertEqual(pack_top2(-1, 3), 0x03FF)
        self.assertEqual(pack_top2(-128, -128), 0x8080)

    def test_golden_known_values(self):
        self.assertEqual(top2_4_golden(0x7F80FF01), 0x017F)
        self.assertEqual(top2_4_golden(0x0380FFFB), 0xFF03)
        self.assertEqual(top2_4_golden(0x05050505), 0x0505)
        self.assertEqual(top2_4_golden(0x80808080), 0x8080)
        self.assertEqual(top2_4_golden(0x00010203), 0x0203)
        self.assertEqual(top2_4_golden(0xFFFEFDFC), 0xFEFF)

    def test_golden_duplicates(self):
        self.assertEqual(top2_4_values(0x05050505), (5, 5))
        self.assertEqual(top2_4_values(0x7F7F7F7F), (127, 127))
        self.assertEqual(top2_4_values(0x80808080), (-128, -128))

    def test_golden_negative_lanes(self):
        self.assertEqual(top2_4_values(0x0380FFFB), (3, -1))
        self.assertEqual(top2_4_values(0xFFFEFDFC), (-1, -2))

    def test_golden_random_against_sort(self):
        rng = random.Random(20261031)
        for _ in range(10000):
            word = rng.getrandbits(32)
            lanes = sorted(unpack_int8(word), reverse=True)
            self.assertEqual(top2_4_golden(word), pack_top2(lanes[0], lanes[1]))

    def test_apply_reads_rs1_and_writes_rd(self):
        regs = [0] * 32
        regs[11] = 0x7F80FF01
        apply_top2_4(regs, 10, 11)
        self.assertEqual(regs[10], 0x017F)
        self.assertEqual(regs[11], 0x7F80FF01)

    def test_apply_x0_semantics(self):
        regs = [0] * 32
        regs[11] = 0x7F80FF01
        apply_top2_4(regs, 0, 11)
        self.assertEqual(regs[0], 0)
        apply_top2_4(regs, 10, 0)
        self.assertEqual(regs[10], 0x0000)

    def test_opcode_is_custom0(self):
        self.assertEqual(OPCODE_CUSTOM0, 0x0B)
        self.assertEqual(encode_top2_4(0, 0) & 0x7F, 0x0B)


if __name__ == "__main__":
    unittest.main()
