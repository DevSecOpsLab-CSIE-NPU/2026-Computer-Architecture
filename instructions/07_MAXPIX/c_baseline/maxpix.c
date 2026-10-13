#include "maxpix.h"

/*
 * 將 packed 的四個 byte 視為無號像素，由最低有效 byte 到最高有效 byte
 * 依序為 b0、b1、b2、b3，回傳其中的最大值。
 */
uint32_t maxpix(uint32_t packed)
{
    /* 右移後遮罩低 8 位，取出各個像素；uint32_t 避免有號比較問題。 */
    uint32_t b0 = packed & UINT32_C(0xff);
    uint32_t b1 = (packed >> 8) & UINT32_C(0xff);
    uint32_t b2 = (packed >> 16) & UINT32_C(0xff);
    uint32_t b3 = (packed >> 24) & UINT32_C(0xff);

    /* 先分別求兩組的最大值，再比較兩組最大值，總共比較三次。 */
    uint32_t max01 = b0 > b1 ? b0 : b1;
    uint32_t max23 = b2 > b3 ? b2 : b3;
    return max01 > max23 ? max01 : max23;
}
