MODULES += \
  uctl.package \
  uctl.num \
  uctl.fix \
  uctl.unit \
  uctl.math.package \
  uctl.math.trig \
  uctl.util.package \
  uctl.util.val \
  uctl.util.dl \
  uctl.util.lt \
  uctl.test

SOURCES = $(patsubst %,%.d,$(subst .,/,$(MODULES)))
TESTS = $(patsubst %,test.%,$(filter-out %.package,$(MODULES)))

#DFLAGS += -d-version=fixDouble
#DFLAGS += -d-version=fixRoundDown
#DFLAGS += -d-version=fixRoundToZero
#DFLAGS += -d-version=fixRoundToNearest
DFLAGS += -d-debug
#DFLAGS += -v

DENV += betterc # or druntime
DENV += debug # or release

ifneq ($(filter betterc,$(DENV)),)
DFLAGS += -betterC -nogc
endif

ifneq ($(filter druntime,$(DENV)),)
DFLAGS += -main
endif

ifeq ($(filter debug,$(DENV)),)
DFLAGS += -O0 -g -gc -d-debug
endif

ifeq ($(filter release,$(DENV)),)
DFLAGS += -Os -release
endif

info:
	@echo MODULES=$(MODULES)
	@echo SOURCES=$(SOURCES)
	@echo TESTS=$(TESTS)

prepare:
	@mkdir -p obj

define module_rules
mod.$(1) := $$(subst .,/,$(1))
src.$(1) := $$(patsubst %,%.d,$$(mod.$(1)))
obj.$(1) := $$(patsubst %,obj/%.o,$$(mod.$(1)))

test.$(1): $$(src.$(1)) prepare
	@echo TEST $(1)
	@ldc2 -od=obj -of=obj/$(1) $(DFLAGS) -unittest $$<
	@obj/$(1)

debug.$(1): $$(src.$(1)) prepare
	@echo DEBUG $(1)
	@ldc2 -od=obj -of=obj/$(1) $(DFLAGS) -unittest $$<
	@gdb obj/$(1)

dump.$(1): $$(src.$(1)) prepare
	@echo DUMP $(1)
	@ldc2 -od=obj -of=obj/$(1) $(DFLAGS) -unittest $$<
	@objdump -D -S obj/$(1) | less
endef

$(foreach module,$(MODULES),$(eval $(call module_rules,$(module))))

test: $(TESTS)

doc: $(SOURCES)
	@mkdir -p doc
	@ldc2 -preview=markdown -o- -D -Dd=doc -X -Xf=doc/db.json $^
	@dub run ddox -- filter doc/db.json --only-documented
	@cp -r $(HOME)/.dub/packages/ddox-*/ddox/public/* doc
	@dub run ddox -- generate-html doc/db.json doc

clean:
	@echo CLEAN ALL
	@rm -rf obj doc

.PHONY: test doc clean
