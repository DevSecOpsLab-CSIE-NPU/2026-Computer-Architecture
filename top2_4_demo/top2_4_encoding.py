"""TOP2_4 custom instruction: encoding, golden model, and register semantics.

Instruction:  top2_4 rd, rs1
Semantics:    rs1 contains four signed INT8 lanes.  The instruction finds the
              largest and second-largest lane and writes them to rd:

                  rd[7:0]   = max
                  rd[15:8]  = second
                  rd[31:16] = 0

Format:       R-type on custom-0 opcode (0b0001011 = 0x0B)
              funct3 = 0b110, funct7 = 0b0000000
              rs2 is ignored; canonical encodings use rs2 = x0 = 0.
"""

OPCODE_CUSTOM0 = 0b0001011
FUNCT3_TOP2_4 = 0b110
FUNCT7_TOP2_4 = 0b0000000
MASK32 = 0xFFFF_FFFF


def _check_reg(name: str, value: int) -> None:
    if not 0 <= value <= 31:
        raise ValueError(f"{name} out of range: {value}")


def encode_top2_4(rd: int, rs1: int, rs2: int = 0) -> int:
    """Encode `top2_4 rd, rs1` (rs2 is ignored, canonical value is 0)."""
    _check_reg("rd", rd)
    _check_reg("rs1", rs1)
    _check_reg("rs2", rs2)
    return (
        (FUNCT7_TOP2_4 << 25)
        | (rs2 << 20)
        | (rs1 << 15)
        | (FUNCT3_TOP2_4 << 12)
        | (rd << 7)
        | OPCODE_CUSTOM0
    )


def decode_top2_4(word: int):
    """Return (rd, rs1, rs2) if the word is a TOP2_4 instruction, else None."""
    if word & 0x7F != OPCODE_CUSTOM0:
        return None
    if (word >> 12) & 0x7 != FUNCT3_TOP2_4:
        return None
    if (word >> 25) != FUNCT7_TOP2_4:
        return None
    return (word >> 7) & 0x1F, (word >> 15) & 0x1F, (word >> 20) & 0x1F


def sext8(value: int) -> int:
    """Interpret the low 8 bits as a signed two's-complement integer."""
    value &= 0xFF
    return value - 0x100 if value & 0x80 else value


def unpack_int8(packed: int):
    """Return the four signed INT8 lanes in little-endian order."""
    return tuple(sext8(packed >> (8 * i)) for i in range(4))


def pack_top2(max_value: int, second_value: int) -> int:
    """Pack the result as {second[15:8], max[7:0]} with a zero upper half."""
    return ((second_value & 0xFF) << 8) | (max_value & 0xFF)


def top2_4_values(packed: int):
    """Golden model returning (max, second), duplicates allowed."""
    lanes = unpack_int8(packed)
    ordered = sorted(lanes, reverse=True)
    return ordered[0], ordered[1]


def top2_4_golden(packed: int) -> int:
    """Golden model returning the architectural rd value."""
    max_value, second_value = top2_4_values(packed)
    return pack_top2(max_value, second_value)


def apply_top2_4(regs, rd: int, rs1: int, rs2: int = 0) -> None:
    """Architectural effect on a 32-entry register file.

    Reads of x0 return 0 and writes to x0 are discarded.  rs2 is ignored, but
    the parameter is kept so the call shape matches the R-type encoding.
    """
    del rs2
    regs[0] = 0
    if rd == 0:
        return
    regs[rd] = top2_4_golden(regs[rs1])


if __name__ == "__main__":
    word = encode_top2_4(10, 11)
    print(f"top2_4 a0, a1  ->  0x{word:08x}  {word:032b}")
    print("decode:", decode_top2_4(word))

    example = 0x7F80FF01
    print(f"input 0x{example:08x} lanes={unpack_int8(example)}")
    print(f"result 0x{top2_4_golden(example):08x} values={top2_4_values(example)}")
