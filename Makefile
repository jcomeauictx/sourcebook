# bashisms in Makefile, cannot use old sh
SHELL := /bin/bash
BUILD ?= xacpi
# BORDER used by ImageMagick convert to whiteout anything in margins
# change BGCOLOR to something noticeable like green for debugging
BGCOLOR ?= white
# to whiteout only certain pages:
# `make PAGES='page0024.pdf page0123.pdf' doc.whiteout.pdf`
PAGES ?= ALL
TYPE := $(suffix $(BUILD))
# valid BUILDTYPEs are pdf, kindle, and paperback
# this approach can be problematic if dots are in repo names
ifeq ($(TYPE),)
 BUILDTYPE ?= pdf
else
 BUILDTYPE=$(replace .,,$(TYPE))
endif
ifeq ($(BUILDTYPE),kindle)
 BORDER ?= 70
else ifeq ($(BUILDTYPE),pdf)
 BORDER ?= 58
else ifeq ($(BUILDTYPE),paperback)
 BORDER ?= 50
endif
MAKE := make -s
REPONAME ?= $(BUILD:.$(BUILDTYPE)=)
BOOKTITLE ?= $(REPONAME)
ifeq ($(REPONAME),SATsign)
 AUTHOR ?= Christian Cruz and John Comeau
else
 AUTHOR ?= John Comeau
endif
PUBLISHER ?= lotecnotec press
FILES ?= $(filter-out LICENSE, $(shell cd ../$(REPONAME) && git ls-files))
SUBDIRS ?= $(sort $(dir $(FILES)))
SUBDIR ?=
PARTS := $(BUILD).bookstart.tex $(BUILD).intro.tex $(BUILD).license.tex
PARTS += $(BUILD).sources.tex
FINAL_PART := $(BUILD).trailer.tex
# mapping suffixes to languages
.sh := bash
.html := HTML
.py := Python
.mk := make
.php := PHP
.tex := TeX
.c := C
.cpp := C++
.java := Java
# "bad" suffixes that shouldn't show up in listings
.pdf := BAD
.der := BAD
.cer := BAD
.crt := BAD
.0 := BAD
.exe := BAD
# rename .min.js files to .minjs: will this work though?
.minjs := BAD
# mapping non-suffixed filenames to languages
Makefile := make
README := HTML # not really, just for testing language detection
# get language from listing path
LISTING ?=
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
default: pdf
all: env $(BUILD).view $(BUILD).save
$(BUILD).tex: $(PARTS) | $(FINAL_PART)
	cat $+ > $@
	for subdir in $(SUBDIRS); do \
	 $(MAKE) SUBDIR=$$subdir $(BUILD).subdir >> $@; \
	 for file in $(FILES); do \
	  $(MAKE) SUBDIR=$$subdir LISTING=$$file $(BUILD).listing >> $@; \
	 done; \
	done
	cat $| >> $@
%.cover.jpg: %.cover.pdf
	pdftoppm $< | ppmtojpeg > $@
%.save: %.pdf %.cover.pdf %.cover.jpg
	mkdir -p $(HOME)/sourcebook
	cp -f $+ $(HOME)/sourcebook/
$(REPONAME).%.subdir: %.subdir.template.tex
	envsubst < $<
$(REPONAME).%.listing: %.source.template.tex
	@echo % conditionally making listing for $(LISTING) in $(SUBDIR)
	if [ "$$(dirname $(LISTING))/" = "$(SUBDIR)" ]; then \
	 if [ "$($(SUFFIX))" != "BAD" ]; then \
	  envsubst < $<; \
	 else \
	  echo % $(FILENAME) is not a valid listing; \
	 fi; \
	else \
	 echo % $(LISTING) not in $(SUBDIR); \
	fi
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
	git push origin
	git push githost
%.cover.pdf: %.cover.tex
	pdflatex $<
%.pdf: %.tex
	# the || true lets us continue to create the cover
	pdflatex -shell-escape -interaction nonstopmode $< || true
$(REPONAME).pdf.%.tex: pdf.%.template.tex Makefile
	envsubst < $< > $@
$(REPONAME).kindle.%.tex: kindle.%.template.tex Makefile
	envsubst < $< > $@
$(REPONAME).paperback.%.tex: paperback.%.template.tex Makefile
	# prevent incomplete cover code from being generated
	if [ "$*" != "cover" ]; then \
	 envsubst < $< > $@; \
	elif [ -s "$(@:.cover.tex=.pdf)" ]; then \
	 pages=$$(pdfinfo $(@:.cover.tex=.pdf) | \
	  awk '$$1 ~ /^Pages:/ {print $$2}'); \
	 coverwidth=$$(printf %.03f $$(echo "$$pages*.00225+12.25" | bc)); \
	 echo '*****CHECK*****' pages $$pages coverwidth $$coverwidth >&2; \
	 COVERWIDTH=$$coverwidth envsubst < $< > $@; \
	else \
	 echo not generating cover until $(@:.cover.tex=.pdf) complete >&2; \
	fi
%.view: %.pdf %.cover.pdf %.cover.jpg
	rm -f $+  # remove and rebuild to ensure Contents are complete
	$(MAKE) $+
	xpdf $<
	display $*.cover.jpg
%.view: %.pdf
	xpdf $<
kindle paperback pdf:
	$(MAKE) BUILD=$(BUILD).$@ all
# recipes to truncate lines that bleed into margins
# from https://stackoverflow.com/a/39726873/493161
# however, this degrades the print quality noticeably, and changing
# ImageMagick's delegation to pnmraw as in
# https://stackoverflow.com/a/16435640/493161 didn't help.
# so, best to use whiteout's `convert` command only on the necessary
# pages before running pdunite. That way the bad print is only on the
# affected pages.
%.whiteout.pdf: %.pdf .FORCE
	tempdir=$$(mktemp -d); \
	 pdfseparate $< $$tempdir/page%04d.pdf; \
	 for page in $$tempdir/page*; do \
	  echo processing $$page... >&2; \
	  if [[ $(PAGES) = ALL || $(PAGES) = *$$(basename $$page)* ]]; then \
	   echo converting $$page... >&2; \
	   convert $$page -gravity east -chop $(BORDER)x \
	    -background $(BGCOLOR) \
	    -splice $(BORDER)x \
	    $$page.withborder.pdf; \
	  else \
	   echo skipping page $$page... >&2; \
	   mv $$page $$page.unchanged.withborder.pdf; \
	  fi; \
	 done; \
	pdfunite $$tempdir/*.withborder.pdf $@
	xpdf $@
%.borders.pdf: %.pdf
	tempdir=$$(mktemp -d); \
	 pdfseparate $< $$tempdir/page%04d.pdf; \
	 for page in $$tempdir/page*; do \
	  convert $$page -shave $(BORDER)x$(BORDER) \
	   -bordercolor $(BGCOLOR) \
	   -border $(BORDER) \
	   $$page.withborder.pdf; \
	 done; \
	pdfunite $$tempdir/*.withborder.pdf $@
.PRECIOUS: %.pdf %.cover.tex %.cover.pdf %.cover.jpg
.FORCE:
