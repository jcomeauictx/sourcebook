REPONAME ?= kybyz
FILES ?= $(shell cd ../$(REPONAME) && git ls-files)
ifeq ($(SHOWENV),)
	# not exporting all globals
else
	export
endif
test: convert
	./$< $(FILES)
clean:
	rm -f *.pdf *.aux *.log listing.tex
env:
ifeq ($(SHOWENV),)
	$(MAKE) SHOWENV=1 $@
else
	$@
endif
