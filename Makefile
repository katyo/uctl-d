DFLAGS += -d-version=fixRound

app.elf: main.o fix.o
	cc -Wl,--gc-sections $^ -o $@
	size $@

%.o: %.d
	ldc2 -c -betterC -nogc $(DFLAGS) $<

%.test: %.d
	ldc2 -g $(DFLAGS) -betterC -nogc -unittest $<
	./$*
	rm $*

test: fix.test

doc: fix.d
	ldc2 -o- -D -X -Xfdocs.json $^
	mkdir -p doc
	cp -r $(HOME)/.dub/packages/ddox-*/ddox/public/* doc
	dub run ddox -- generate-html docs.json doc

clean:
	rm -f *.o *.elf

.PHONY: doc clean
