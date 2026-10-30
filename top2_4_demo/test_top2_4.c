#include "top2_4.h"

#include <stdint.h>
#include <stdio.h>

static int failures;

#define EXPECT_EQ_U32(actual, expected)                                              \
    do {                                                                             \
        uint32_t a_ = (uint32_t)(actual), e_ = (uint32_t)(expected);                 \
        if (a_ != e_) {                                                              \
            printf("FAIL %s:%d: %s = 0x%08x, expected 0x%08x\n", __FILE__, __LINE__, \
                   #actual, a_, e_);                                                 \
            failures++;                                                              \
        }                                                                            \
    } while (0)

static uint32_t pack4(int32_t a, int32_t b, int32_t c, int32_t d)
{
    return ((uint32_t)a & 0xFF) | (((uint32_t)b & 0xFF) << 8) |
           (((uint32_t)c & 0xFF) << 16) | (((uint32_t)d & 0xFF) << 24);
}

static uint32_t top2_4_slow(uint32_t packed)
{
    int32_t lanes[4] = {
        (int8_t)(packed),
        (int8_t)(packed >> 8),
        (int8_t)(packed >> 16),
        (int8_t)(packed >> 24),
    };

    for (int i = 0; i < 4; i++) {
        for (int j = i + 1; j < 4; j++) {
            if (lanes[j] > lanes[i]) {
                int32_t tmp = lanes[i];
                lanes[i] = lanes[j];
                lanes[j] = tmp;
            }
        }
    }

    return ((uint32_t)lanes[1] & 0xFF) << 8 | ((uint32_t)lanes[0] & 0xFF);
}

static void test_known_values(void)
{
    EXPECT_EQ_U32(top2_4_ref(pack4(1, -1, -128, 127)), 0x017F);
    EXPECT_EQ_U32(top2_4_ref(pack4(-5, -1, -128, 3)), 0xFF03);
    EXPECT_EQ_U32(top2_4_ref(pack4(5, 5, 5, 5)), 0x0505);
    EXPECT_EQ_U32(top2_4_ref(pack4(-128, -128, -128, -128)), 0x8080);
    EXPECT_EQ_U32(top2_4_ref(pack4(3, 2, 1, 0)), 0x0203);
    EXPECT_EQ_U32(top2_4_ref(pack4(-4, -3, -2, -1)), 0xFEFF);
    EXPECT_EQ_U32(top2_4_ref(pack4(127, -128, 0, -1)), 0x007F);
}

static void test_custom_matches_reference(void)
{
    EXPECT_EQ_U32(top2_4_insn(pack4(1, -1, -128, 127)), top2_4_ref(pack4(1, -1, -128, 127)));
    EXPECT_EQ_U32(top2_4_insn(pack4(-5, -1, -128, 3)), top2_4_ref(pack4(-5, -1, -128, 3)));
    EXPECT_EQ_U32(top2_4_insn(pack4(5, 5, 5, 5)), top2_4_ref(pack4(5, 5, 5, 5)));
}

static void test_random_matches_slow_model(void)
{
    uint32_t seed = 20261031u;
    for (int trial = 0; trial < 10000; trial++) {
        seed ^= seed << 13;
        seed ^= seed >> 17;
        seed ^= seed << 5;
        EXPECT_EQ_U32(top2_4_ref(seed), top2_4_slow(seed));
        EXPECT_EQ_U32(top2_4_insn(seed), top2_4_slow(seed));
    }
}

int main(void)
{
    test_known_values();
    test_custom_matches_reference();
    test_random_matches_slow_model();

    if (failures) {
        printf("%d C test(s) failed\n", failures);
        return 1;
    }
    printf("all C tests passed\n");
    return 0;
}
