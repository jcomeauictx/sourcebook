BUILD ?= xacpi
MAKE := make -s
REPONAME ?= $(BUILD:$(suffix $(BUILD))=)
BOOKTITLE ?= $(REPONAME)
AUTHOR ?= John Otis Comeau
PUBLISHER ?= lotecnotec press
FILES ?= $(filter-out LICENSE, $(shell cd ../$(REPONAME) && git ls-files))
PARTS := $(BUILD).bookstart.tex $(BUILD).intro.tex $(BUILD).license.tex
PARTS += $(BUILD).sources.tex
FINAL_PART := $(BUILD).trailer.tex
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
all: $(BUILD).view $(BUILD).save
$(BUILD).tex: $(PARTS) | $(FINAL_PART)
	cat $+ > $@
	for file in $(FILES); do $(MAKE) LISTING=$$file texout >> $@; done
	cat $| >> $@
%.cover.jpg: %.cover.pdf
	pdftoppm $< | ppmtojpeg > $@
%.cover.tex: kindle.cover.template.tex
	envsubst < $< > $@
%.save: %.pdf %.cover.jpg
	mkdir -p $(HOME)/sourcebook
	cp -f $+ $(HOME)/sourcebook/
texout: source.template.tex
	envsubst < $<
test: convert
	./$< $(FILES)
clean:
	rm -f *.aux *.log *.toc *.lua *.out *.err
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
$(REPONAME).kindle.%.tex: kindle.%.template.tex Makefile
	envsubst < $< > $@
%.view: %.pdf %.cover.pdf %.cover.jpg
	rm -f $+  # remove and rebuild to ensure Contents are complete
	$(MAKE) $+
	xpdf $<
	display $*.cover.jpg
kindle:
	$(MAKE) BUILD=$(BUILD).kindle all
.PRECIOUS: %.pdf %.cover.tex %.cover.jpg
