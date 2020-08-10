SOURCES += num.d fix.d test.d lt.d util.d unit.d
#DFLAGS += -d-version=fixDouble
#DFLAGS += -d-version=fixRoundToZero
#DFLAGS += -d-version=fixRoundToNearest
DFLAGS += -d-debug
#DFLAGS += -v

DENV ?= bc

ifeq ($(DENV),bc) # betterC
DFLAGS += -betterC -nogc
endif

ifeq ($(DENV),rt) # runtime
DFLAGS += -main
endif

test.%: %.d
	ldc2 -g $(DFLAGS) -betterC -nogc -unittest $<
	./$*
	rm $*

debug.%: %.d
	ldc2 -g $(DFLAGS) -betterC -nogc -unittest $<
	gdb ./$*
	rm $*

dump.%: %.d
	ldc2 -g $(DFLAGS) -betterC -nogc -unittest $<
	objdump -D -S $* | less
	rm $*

test: $(patsubst %.d,test.%,$(SOURCES))

doc: $(SOURCES)
	ldc2 -preview=markdown -o- -D -X -Xfdoc.json $^
	dub run ddox -- filter doc.json --only-documented
	mkdir -p doc
	cp -r $(HOME)/.dub/packages/ddox-*/ddox/public/* doc
	dub run ddox -- generate-html doc.json doc

clean:
	rm -f *.o *.elf

.PHONY: test doc clean
