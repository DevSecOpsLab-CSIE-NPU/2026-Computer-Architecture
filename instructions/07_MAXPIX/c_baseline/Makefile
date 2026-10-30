CC ?= cc
CFLAGS ?= -std=c11 -Wall -Wextra -Wpedantic -O2

.PHONY: all test clean

all: test_maxpix

test_maxpix: maxpix.c test_maxpix.c maxpix.h
	$(CC) $(CFLAGS) maxpix.c test_maxpix.c -o $@

test: test_maxpix
	./test_maxpix

clean:
	rm -f test_maxpix
