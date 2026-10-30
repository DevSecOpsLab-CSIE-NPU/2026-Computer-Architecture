#include "maxpix.h"

uint32_t maxpix(uint32_t pixel_word)
{
    uint32_t max_value = pixel_word & UINT32_C(0xff);

    for (unsigned shift = 8; shift < 32; shift += 8) {
        const uint32_t pixel = (pixel_word >> shift) & UINT32_C(0xff);
        if (pixel > max_value) {
            max_value = pixel;
        }
    }

    return max_value;
}
