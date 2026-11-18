BUILD_DIR := build
IVERILOG  ?= iverilog
VVP       ?= vvp
YOSYS     ?= yosys
NEXTPNR   ?= nextpnr-ice40
ICEPACK   ?= icepack

RTL   := rtl/top2_4.sv rtl/top_icebreaker.sv
TB    := tb/tb_top2_4.sv
PCF   := constraints/icebreaker.pcf

.PHONY: all test synth pnr clean

all: $(BUILD_DIR)/top2_4.bin

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

test: | $(BUILD_DIR)
	$(IVERILOG) -g2012 -s tb_top2_4 -o $(BUILD_DIR)/tb_top2_4.vvp rtl/top2_4.sv $(TB)
	$(VVP) $(BUILD_DIR)/tb_top2_4.vvp

synth: | $(BUILD_DIR)
	$(YOSYS) -p "read_verilog -sv $(RTL); synth_ice40 -top top_icebreaker -json $(BUILD_DIR)/top2_4.json"

pnr: $(BUILD_DIR)/top2_4.asc

$(BUILD_DIR)/top2_4.asc: $(BUILD_DIR)/top2_4.json $(PCF)
	$(NEXTPNR) --up5k --package sg48 --json $< --pcf $(PCF) --asc $@

$(BUILD_DIR)/top2_4.bin: $(BUILD_DIR)/top2_4.asc
	$(ICEPACK) $< $@

$(BUILD_DIR)/top2_4.json: $(RTL) | $(BUILD_DIR)
	$(YOSYS) -p "read_verilog -sv $(RTL); synth_ice40 -top top_icebreaker -json $@"

clean:
	rm -rf $(BUILD_DIR)
