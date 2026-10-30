typedef unsigned int u32;

u32 top2_4_probe(u32 packed)
{
    u32 result;
    __asm__ volatile(".insn r 0x0b, 6, 0, %0, %1, x0"
                     : "=r"(result)
                     : "r"(packed));
    return result;
}
