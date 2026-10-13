#ifndef MAXPIX_H
#define MAXPIX_H
#include <stdint.h>

/* 輸入為四個打包的無號 8-bit 像素，回傳最大像素值 (0–255)。 */
uint32_t maxpix(uint32_t packed);
#endif
