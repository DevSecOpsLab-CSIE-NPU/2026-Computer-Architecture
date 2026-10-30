#include "top2_4.h"

static inline int32_t imax(int32_t a, int32_t b)
{
    return a > b ? a : b;
}

static inline int32_t imin(int32_t a, int32_t b)
{
    return a < b ? a : b;
}

uint32_t top2_4_ref(uint32_t packed)
{
    int32_t a = (int8_t)(packed);
    int32_t b = (int8_t)(packed >> 8);
    int32_t c = (int8_t)(packed >> 16);
    int32_t d = (int8_t)(packed >> 24);

    int32_t a1 = imax(a, b);
    int32_t b1 = imin(a, b);
    int32_t c1 = imax(c, d);
    int32_t d1 = imin(c, d);

    int32_t max_value = imax(a1, c1);
    int32_t second_value = imax(imin(a1, c1), imax(b1, d1));

    return (uint32_t)(((second_value & 0xFF) << 8) | (max_value & 0xFF));
}
