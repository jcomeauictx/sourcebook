REPONAME ?= xacpi
BOOKTITLE ?= $(REPONAME)
AUTHOR ?= John Otis Comeau
PUBLISHER ?= lotecnotec press
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
	export REPONAME AUTHOR PUBLISHER BOOKTITLE LANGUAGE LISTING FILEPATH
else
	export
endif
all: $(REPONAME).view $(REPONAME).save kindle
$(REPONAME).tex: $(PARTS) | $(FINAL_PART)
	cat $+ > $@
	for file in $(FILES); do $(MAKE) LISTING=$$file -s texout >> $@; done
	cat $| >> $@
%.cover.kindle.jpg: %.cover.kindle.pdf
	pdftoppm $< | ppmtojpeg > $(*:.kindle=).cover.kindle.jpg
%.cover.kindle.tex: cover.kindle.template.tex
	envsubst < $< > $(*:.kindle=).kindle.tex
%.save: %.pdf %.cover.kindle.jpg
	mkdir -p $(HOME)/sourcebook
	cp -f $+ $(HOME)/sourcebook/
texout: source.template.tex
	envsubst < $<
test: convert
	./$< $(FILES)
clean:
	rm -f *.aux *.log *.toc *.lua *.out
	rm -rf _markdown_*
distclean: clean
	rm -f *.pdf $(filter-out $(wildcard *.template.tex), $(wildcard *.tex))
	rm -f *.jpg
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
%.view: %.pdf %.cover.kindle.pdf %.cover.kindle.jpg
	rm -f $+  # remove and rebuild to ensure Contents are complete
	$(MAKE) $+
	xpdf $<
	display $(*:.kindle=).cover.kindle.jpg
kindle:
	$(MAKE) REPONAME=$(REPONAME).kindle all
.PRECIOUS: %.pdf %.cover.kindle.tex %.cover.kindle.jpg
