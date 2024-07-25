VENV = fusesoc.venv

export PATH := $(VENV)/bin:$(PATH)

PYTHON = python
CC = or1k-elf-gcc
CFLAGS = -ffunction-sections -fdata-sections -mcmov -msext -msfimm -mshftimm \
	 -Os -fno-move-loop-invariants
LDFLAGS = -Wl,--gc-sections,-z,max-page-size=0x10 -nostartfiles \
	  -Wl,--section-start=.vectors=0x2000

BOARDLIB = board-or1ksim-uart

FUSESOC = $(VENV)/bin/fusesoc
FUSESOCFLAGS = --monochrome
FEATURES = --feature_immu NONE --feature_dmmu NONE --feature_datacache NONE \
	   --feature_fastcontexts ENABLED
OPTIONS = --option_rf_num_shadow_gpr 1
# TRACEFLAGS = --trace_enable --trace_to_screen
# VCDFLAGS = --vcd

run_test : testprog $(FUSESOC) | fusesoc.conf
	$(FUSESOC) $(FUSESOCFLAGS) run --target mor1kx_tb --tool icarus --flag +small_mem mor1kx-generic $(FEATURES) $(OPTIONS) --elf_load ./testprog $(TRACEFLAGS) $(VCDFLAGS)

testprog : entry.S main.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ -l$(BOARDLIB) -Wl,-Map,testprog.map

$(VENV)/bin/fusesoc : | $(VENV)
	$(VENV)/bin/pip --require-virtualenv install fusesoc

$(VENV) :
	$(PYTHON) -m venv $@

fusesoc.conf : | $(FUSESOC)
	$(FUSESOC) $(FUSESOCFLAGS) library add fusesoc-cores https://github.com/fusesoc/fusesoc-cores
	$(FUSESOC) $(FUSESOCFLAGS) library add intgen https://github.com/stffrdhrn/intgen.git
	$(FUSESOC) $(FUSESOCFLAGS) library add elf-loader https://github.com/fusesoc/elf-loader.git
	$(FUSESOC) $(FUSESOCFLAGS) library add mor1kx-generic $(CURDIR)/mor1kx-generic
	$(FUSESOC) $(FUSESOCFLAGS) library add mor1kx $(CURDIR)/mor1kx
