MODULES += \
  uctl.package \
  uctl.num \
  uctl.unit \
  uctl.math.package \
  uctl.math.trig \
  uctl.math.log \
  uctl.math.util \
  uctl.util.package \
  uctl.util.adj \
  uctl.util.dl \
  uctl.util.lt \
  uctl.util.sort \
  uctl.util.win \
  uctl.util.osc \
  uctl.util.vec \
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
  uctl.simul.package \
  uctl.simul.htr \
  uctl.simul.dcm \
  uctl.simul.thr \
  uctl.modul.package \
  uctl.modul.swm \
  uctl.modul.svm \
  uctl.modul.psc \
  uctl.test

PLOTS += \
  trig_errs \
  win_funcs \
  filt_ema \
  sim_htr \
  sim_pid_htr \
  sim_dcm \
  thr_fit \
  mod_swm \
  mod_svm \
  mod_svm_psc

TARGET ?= x86_64-linux-gnu

#DFLAGS += -d-version=fixDouble
#DFLAGS += -d-version=fixRoundDown
#DFLAGS += -d-version=fixRoundToZero
#DFLAGS += -d-version=fixRoundToNearest

DENV += betterc # or druntime
DENV += debug # or release
# DENV += verbose

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

parse_triple = $(subst -, ,$(1))
gcc_arch = $(patsubst armv%,arm,$(word 1,$(call parse_triple,$(1))))
gcc_os = $(word $(if $(filter 3,$(words $(call parse_triple,$(1)))),2,3),$(call parse_triple,$(1)))
gcc_libc = $(word $(if $(filter 3,$(words $(call parse_triple,$(1)))),3,4),$(call parse_triple,$(1)))
gcc_tool = $(call gcc_arch,$(1))-$(call gcc_os,$(1))-$(call gcc_libc,$(1))$(if $(2),-$(2))

ifneq ($(TARGET),)
    DFLAGS += -mtriple=$(TARGET) -gcc=$(call gcc_tool,$(TARGET),gcc)
endif

BUILD_DIR = obj/$(TARGET)
DC = ldc2 -od=$(BUILD_DIR) -of=$(2) $(3) $(1)

ifeq ($(RUNNER),qemu)
	  RUN = qemu-$(call gcc_arch,$(TARGET)) -L /usr/$(call gcc_tool,$(TARGET)) $(1)
else
    RUN = $(1)
endif

.SECONDARY: prepare
prepare:
	@mkdir -p $(BUILD_DIR)

define module_rules
mod.$(1) := $$(subst .,/,$(1))
src.$(1) := $$(patsubst %,%.d,$$(mod.$(1)))
obj.$(1) := $$(patsubst %,$(BUILD_DIR)/%.o,$(1))
bin.$(1) := $$(patsubst %,$(BUILD_DIR)/%,$(1))

ifeq ($(filter %.package,$(1)),)
build: build.$(1)
test: test.$(1)

$$(bin.$(1)): $$(src.$(1)) prepare
	@echo DC $(1)
	@$$(call DC,$$<,$$@,$(DFLAGS) -unittest)

build.$(1): $$(bin.$(1))

test.$(1): $$(bin.$(1))
	@echo TEST $(1)
	@$$(call RUN,$$<)

debug.$(1): $$(bin.$(1))
	@echo DEBUG $(1)
	@gdb $$<

dump.$(1): $$(bin.$(1))
	@echo DUMP $(1)
	@objdump -D -S $$< | less
endif
endef

$(foreach module,$(MODULES),$(eval $(call module_rules,$(module))))

define plot_rules
plot: plot.$(1)

plot.$(1): plot/$(1).svg

plot/$(1).svg: plot/$(1).m #uctl
	@echo PLOT $(1)
	@cd $$(dir $$<) && octave $$(notdir $$<)
endef

$(foreach plot,$(PLOTS),$(eval $(call plot_rules,$(plot))))

doc: uctl
	@echo DOC
	@adrdox -i --tex-math=katex -o doc $<
	@cp plot/*.svg doc

clean:
	@echo CLEAN ALL
	@rm -rf obj doc

.PHONY: build test plot doc clean
