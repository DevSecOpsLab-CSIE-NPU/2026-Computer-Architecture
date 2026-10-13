#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include "maxpix.h"

typedef struct { uint32_t input, expected; } test_case;

/* 測資涵蓋基本案例、全零/全一、無號比較邊界，以及最大值位於不同 byte。 */
static const test_case tests[] = {
    { UINT32_C(0x0A1E2805), 40 },
    { UINT32_C(0x00000000), 0 },
    { UINT32_C(0xFF000001), 255 },
    { UINT32_C(0x01020304), 4 },
    { UINT32_C(0x04030201), 4 },
    { UINT32_C(0x7F807F80), 128 },
    { UINT32_C(0x80808080), 128 },
    { UINT32_C(0xFFFFFFFF), 255 },
    { UINT32_C(0x0100FF00), 255 },
    { UINT32_C(0x000000FF), 255 },
    { UINT32_C(0x01010101), 1 },
    { UINT32_C(0x00010000), 1 },
};

int main(void)
{
    unsigned failures = 0;
    /* 逐筆執行測試，印出預期值與實際值；有任一筆錯誤便回傳非零。 */
    for (unsigned i = 0; i < sizeof tests / sizeof tests[0]; ++i) {
        uint32_t actual = maxpix(tests[i].input);
        printf("%02u input=0x%08" PRIX32 " expected=%" PRIu32
               " actual=%" PRIu32 " %s\n",
               i + 1, tests[i].input, tests[i].expected, actual,
               actual == tests[i].expected ? "PASS" : "FAIL");
        failures += actual != tests[i].expected;
    }
    printf("%u/%u tests passed\n", (unsigned)(sizeof tests / sizeof tests[0]) - failures,
           (unsigned)(sizeof tests / sizeof tests[0]));
    return failures != 0;
}
