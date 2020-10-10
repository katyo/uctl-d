DFLAGS += -mtriple=wasm32-unknown-unknown-wasm
DFLAGS += -betterC -nogc -fvisibility=hidden
DFLAGS += -I=..
DFLAGS += -release -Oz --boundscheck=off

D_SOURCES := $(wildcard src/modules/*.d src/modules/*/*.d)

dev build export: build-wasm
	@npm run $@

build-wasm:

define wasm_rules
build-wasm: $(2)
$(2): $(1)
	@ldc2 $(DFLAGS) -od=$(dir $(2)) -of=$(2) $(1)
endef

$(foreach d_source,$(D_SOURCES),$(eval $(call wasm_rules,$(d_source),$(patsubst %.d,%.wasm,$(d_source)))))
