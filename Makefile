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
	rm -f *.aux *.log *.toc listing.tex samplebook.*
distclean: clean
	rm -f $(REPONAME).pdf $(REPONAME).tex
env:
ifeq ($(SHOWENV),)
	$(MAKE) SHOWENV=1 $@
else
	$@
endif
