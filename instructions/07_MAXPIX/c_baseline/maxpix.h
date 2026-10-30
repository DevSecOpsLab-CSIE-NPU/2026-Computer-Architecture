#ifndef MAXPIX_H
#define MAXPIX_H

#include <stdint.h>

/* Return the largest of the four unsigned 8-bit pixels packed in pixel_word. */
uint32_t maxpix(uint32_t pixel_word);

#endif
