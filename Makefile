MODULES += \
  uctl.package \
  uctl.num \
  uctl.unit \
  uctl.math.package \
  uctl.math.trig \
  uctl.math.log \
  uctl.util.package \
  uctl.util.val \
  uctl.util.dl \
  uctl.util.lt \
  uctl.util.sort \
  uctl.util.win \
  uctl.filt.package \
  uctl.filt.avg \
  uctl.filt.ema \
  uctl.filt.fir \
  uctl.filt.lqe \
  uctl.filt.med \
  uctl.regul.package \
  uctl.regul.pid \
  uctl.trans.package \
  uctl.trans.clarke \
  uctl.trans.park \
  uctl.test

PLOTS += \
  trig_errs \
  win_funcs \

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

prepare:
	@mkdir -p obj

define module_rules
mod.$(1) := $$(subst .,/,$(1))
src.$(1) := $$(patsubst %,%.d,$$(mod.$(1)))
obj.$(1) := $$(patsubst %,obj/%.o,$$(mod.$(1)))

ifeq ($(filter %.package,$(1)),)
test: test.$(1)

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
endif
endef

$(foreach module,$(MODULES),$(eval $(call module_rules,$(module))))

define plot_rules
plot: plot.$(1)

plot.$(1): doc/$(1).svg

doc/$(1).svg: plot/$(1).m uctl
	cd $$(dir $$<) && octave $$(notdir $$<)
	mv plot/$(1).svg $$@
endef

$(foreach plot,$(PLOTS),$(eval $(call plot_rules,$(plot))))

doc_gen: uctl
	adrdox -i --tex-math=katex -o doc $<

doc: doc_gen plot

clean:
	@echo CLEAN ALL
	@rm -rf obj doc

.PHONY: test plot doc clean
