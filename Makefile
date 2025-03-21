# bashisms in Makefile, cannot use plain sh
SHELL := /bin/bash
BUILD ?= xacpi
# deal with potential spaces in path names (looking at you, ghostscript)
# (better approach adapted from https://stackoverflow.com/a/67346778/493161)
LSREPO := git ls-files --eol | \
 awk '$$1 == "i/lf" {print $$4}' | \
 tr ' ' +
LS := git ls-files --eol ':(glob)*' | \
 awk '$$1 == "i/lf" {print $$4}' | \
 tr ' ' +
# BORDER used by ImageMagick convert to whiteout anything in margins
# change BGCOLOR to something noticeable like green for debugging
BGCOLOR ?= white
# to whiteout only certain pages:
# `make PAGES='page0024.pdf page0123.pdf' doc.whiteout.pdf`
PAGES ?= ALL
TYPE := $(suffix $(BUILD))
# valid BUILDTYPEs are letter, kindle, and paperback
# this approach can be problematic if dots are in repo names
ifeq ($(TYPE),)
 BUILDTYPE ?= letter
else
 BUILDTYPE=$(subst .,,$(TYPE))
endif
ifeq ($(BUILDTYPE),kindle)
 BORDER ?= 64
else ifeq ($(BUILDTYPE),letter)
 BORDER ?= 64
else ifeq ($(BUILDTYPE),paperback)
 BORDER ?= 50
endif
MAKE := make -s
REPONAME ?= $(BUILD:.$(BUILDTYPE)=)
REPOPATH := ../$(REPONAME)
BOOKTITLE ?= $(REPONAME)
ifeq ($(REPONAME),SATsign)
 AUTHOR ?= Christian Cruz and John Comeau
else
 AUTHOR ?= John Comeau
endif
PUBLISHER ?= lotecnotec press
FILES ?= $(shell cd $(REPOPATH) && $(LSREPO))
SUBDIRS ?= $(sort $(dir $(FILES)))
SUBDIR ?=
SECTION := $(subst _,\_,$(SUBDIR))
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
.icc := BAD
.png := BAD
.jpg := BAD
.tiff := BAD
.pgm := BAD
.ppm := BAD
.gif := BAD
.xls := BAD
.ttf := BAD
.xps := BAD
# rename .min.js files to .minjs: will this work though?
.minjs := BAD
# mapping non-suffixed filenames to languages
Makefile := make
README := HTML # not really, just for testing language detection
# binary font resources from casperscript that need to be skipped
# (until I figure out a better way of binary file detection)
NimbusMonoPS-Italic := BAD
Z003-MediumItalic := BAD
NimbusMonoPS-Regular := BAD
URWGothic-Demi := BAD
NimbusSansNarrow-Regular := BAD
NimbusRoman-Italic := BAD
NimbusSansNarrow-Bold := BAD
P052-BoldItalic := BAD
URWGothic-DemiOblique := BAD
C059-Roman := BAD
P052-Roman := BAD
NimbusMonoPS-BoldItalic := BAD
NimbusSansNarrow-BoldOblique := BAD
C059-Italic := BAD
NimbusSans-Bold := BAD
NimbusRoman-Bold := BAD
NimbusSansNarrow-Oblique := BAD
NimbusRoman-BoldItalic := BAD
NimbusSans-Italic := BAD
URWBookman-Demi := BAD
P052-Italic := BAD
C059-Bold := BAD
URWBookman-LightItalic := BAD
NimbusMonoPS-Bold := BAD
NimbusSans-BoldItalic := BAD
ArtifexBullet := BAD
# get language from listing path
LISTING ?=
FILEPATH := $(REPOPATH)/$(SUBDIR)$(LISTING)
CAPTION := $(subst ./,,$(subst _,\_,$(SUBDIR)$(LISTING)))
FILENAME := $(notdir $(LISTING))
SUFFIX := $(suffix $(FILENAME))
LANGUAGE := $(or $($(SUFFIX)),$($(FILENAME)))
ifeq ($(SHOWENV),)
	# not exporting all globals---but at least those needed by templates
	export REPONAME AUTHOR PUBLISHER BOOKTITLE LANGUAGE LISTING \
	 FILEPATH SECTION CAPTION
else
	export $(.VARIABLES)
endif
default: letter
all: env $(BUILD).view $(BUILD).save
$(BUILD).tex: $(PARTS) | $(FINAL_PART)
	cat $+ > $@
	for subdir in $(SUBDIRS); do \
	 $(MAKE) SUBDIR=$$subdir $(BUILD).subdir >> $@; \
	done
	cat $| >> $@
%.cover.jpg: %.cover.pdf
	pdftoppm $< | ppmtojpeg > $@
%.save: %.whiteout.pdf %.cover.pdf %.cover.jpg
	mkdir -p $(HOME)/sourcebook
	cp -f $+ $(HOME)/sourcebook/
$(REPONAME).%.subdir: %.subdir.template.tex
	envsubst < $<
	for file in $$(cd $(REPOPATH)/$(SUBDIR); $(LS)); do \
	 $(MAKE) SUBDIR=$(SUBDIR) LISTING=$$file $(BUILD).listing; \
	done
$(REPONAME).%.listing: %.source.template.tex
	@echo % conditionally making listing for $(FILEPATH) \($(CAPTION)\)
	if [[ "$($(SUFFIX))" != "BAD" && "$(CAPTION)" != "LICENSE" ]]; then \
	 envsubst < $<; \
	else \
	 echo % $(FILENAME) is not a valid listing; \
	fi
clean:
	rm -f *.aux *.log *.toc *.lua *.out *.err
	rm -rf _markdown_*
distclean: clean
	rm -f *.pdf $(filter-out $(wildcard *.template.tex), $(wildcard *.tex))
	rm -f *.jpg
env:
	echo SHOWENV=$(SHOWENV) >&2; \
	if [ -z "$(SHOWENV)" ]; then \
	 $(MAKE) SHOWENV=1 $@; \
	else \
	 $@ | egrep -v '^(LS_COLORS)='; \
	fi
push:
	git push origin
	git push githost
%.cover.pdf: %.cover.tex
	pdflatex $<
%.pdf: %.tex
	# the || true lets us continue to create the cover
	pdflatex -shell-escape -interaction nonstopmode $< || true
$(REPONAME).letter.%.tex: letter.%.template.tex Makefile
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
kindle paperback letter:
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
	   pdftops $$page; \
	   sed -i -e '/^%%Copyright/r $(PWD)/clip.ps' $${page%%.pdf}.ps; \
	   ps2pdf $${page%%.pdf}.ps $$page.withborder.pdf; \
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
%.tdiff:  # compare templates to paperback
	for ttype in bookstart cover intro license sources \
	  source subdir trailer; do \
	 echo diff $*.$$ttype.template.tex paperback.$$ttype.template.tex; \
	 diff $*.$$ttype.template.tex paperback.$$ttype.template.tex; \
	done
.PRECIOUS: %.pdf %.cover.tex %.cover.pdf %.cover.jpg
.FORCE:
