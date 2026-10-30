#ifndef TOP2_4_H
#define TOP2_4_H

#include <stdint.h>

uint32_t top2_4_ref(uint32_t packed);

static inline uint32_t top2_4_insn(uint32_t packed)
{
#if defined(__riscv)
    uint32_t result;
    __asm__ volatile(".insn r 0x0b, 6, 0, %0, %1, x0"
                     : "=r"(result)
                     : "r"(packed));
    return result;
#else
    return top2_4_ref(packed);
#endif
}

#endif
