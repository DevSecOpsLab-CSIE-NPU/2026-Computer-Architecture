#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

extern uint32_t maxpix_rv32im(uint32_t packed_pixels);

typedef struct {
    uint32_t input;
    uint32_t expected;
} TestCase;

static const TestCase test_cases[] = {
    { UINT32_C(0x0a1e2805), 40 },
    { UINT32_C(0x00000000), 0 },
    { UINT32_C(0xff000001), 255 },
    { UINT32_C(0x01020304), 4 },
    { UINT32_C(0x11223344), 68 },
    { UINT32_C(0x7f807f80), 128 },
    { UINT32_C(0x0100ff00), 255 },
    { UINT32_C(0xaaaaaaaa), 170 },
    { UINT32_C(0x00ff00ff), 255 },
    { UINT32_C(0x010101ff), 255 },
    { UINT32_C(0x00000001), 1 },
    { UINT32_C(0xffffffff), 255 },
};

int main(void)
{
    unsigned failures = 0;
    const size_t count = sizeof(test_cases) / sizeof(test_cases[0]);

    for (size_t i = 0; i < count; ++i) {
        const uint32_t actual = maxpix_rv32im(test_cases[i].input);
        if (actual != test_cases[i].expected) {
            fprintf(stderr,
                    "FAIL case %zu: input=0x%08" PRIx32
                    ", expected=%" PRIu32 ", got=%" PRIu32 "\n",
                    i + 1, test_cases[i].input, test_cases[i].expected, actual);
            ++failures;
        }
    }

    if (failures != 0) {
        fprintf(stderr, "%u of %zu cases failed\n", failures, count);
        return 1;
    }

    printf("All %zu RV32IM MAXPIX cases passed.\n", count);
    return 0;
}
