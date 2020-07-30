DFLAGS += -d-version=fixRound
SOURCES += num.d fix.d test.d lt.d util.d unit.d

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
