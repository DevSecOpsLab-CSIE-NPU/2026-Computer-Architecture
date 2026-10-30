CC      ?= cc
CFLAGS  ?= -std=c11 -Wall -Wextra -Werror -O2
PYTHON  ?= python3
RV_GCC  ?= riscv64-elf-gcc

.PHONY: test test-c test-py check-riscv bench clean

test: test-c test-py

test-c: test_top2_4
	./test_top2_4

test_top2_4: test_top2_4.c top2_4.c top2_4.h
	$(CC) $(CFLAGS) -o $@ test_top2_4.c top2_4.c

test-py:
	$(PYTHON) -m unittest discover -s . -p "test_*.py" -v

check-riscv:
	$(RV_GCC) -march=rv32im -mabi=ilp32 -O2 -c riscv_probe.c -o /tmp/top2_4_probe.o
	$(PYTHON) -m unittest test_riscv_encoding -v

bench:
	$(PYTHON) -m benchmark.top2_4_bench

clean:
	rm -f test_top2_4
	rm -rf __pycache__ benchmark/__pycache__
