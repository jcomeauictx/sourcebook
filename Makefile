REPONAME ?= xacpi
BOOKTITLE ?= $(REPONAME)
AUTHOR ?= lotecnotec press
FILES ?= $(shell cd ../$(REPONAME) && git ls-files)
PARTS := $(REPONAME).bookstart.tex $(REPONAME).intro.tex \
 $(REPONAME).sources.tex
FINAL_PART := $(REPONAME).trailer.tex
# mapping suffixes to languages
.sh := bash
.html := HTML
.py := Python
.mk := make
.tex := TeX
# mapping non-suffixed filenames to languages
Makefile := make
README := HTML # not really, just for testing language detection
# get language from listing path
LISTING ?= Makefile.mk
FILEPATH := ../$(REPONAME)/$(LISTING)
FILENAME := $(notdir $(LISTING))
SUFFIX := $(suffix $(FILENAME))
LANGUAGE := $(or $($(SUFFIX)),$($(FILENAME)))
ifeq ($(SHOWENV),)
	# not exporting all globals---but at least those needed by templates
	export REPONAME AUTHOR BOOKTITLE LANGUAGE LISTING FILEPATH
else
	export
endif
all: $(REPONAME).view
$(REPONAME).tex: $(PARTS) | $(FINAL_PART)
	cat $+ > $@
	for file in $(FILES); do $(MAKE) LISTING=$$file -s texout >> $@; done
	cat $| >> $@
texout: source.template.tex
	envsubst < $<
test: convert
	./$< $(FILES)
clean:
	rm -f *.aux *.log *.toc listing.tex overleaf_book.pdf *.lua *.out
	rm -rf _markdown_*
distclean: clean
	rm -f $(REPONAME).pdf $(REPONAME).*.tex $(REPONAME).tex
env:
ifeq ($(SHOWENV),)
	$(MAKE) SHOWENV=1 $@
else
	$@ | egrep -v '^(LS_COLORS)='
endif
push:
	git push -u origin master
	git push -u githost master
%.pdf: %.tex
	pdflatex --shell-escape $<
$(REPONAME).%.tex: %.template.tex Makefile
	envsubst < $< > $@
%.view: %.pdf
	rm -f $<  # remove and rebuild to ensure Contents are complete
	$(MAKE) $<
	xpdf $<
.PRECIOUS: %.pdf
