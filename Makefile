BUILD ?= xacpi.pdf
BUILDTYPE ?= $(suffix $(BUILD))
ifeq ($(BUILDTYPE),)
 BUILDTYPE=pdf
else
 BUILDTYPE=$(replace .,,$(BUILDTYPE))
endif
MAKE := make -s
REPONAME ?= $(BUILD:$(BUILDTYPE)=)
BOOKTITLE ?= $(REPONAME)
AUTHOR ?= John Otis Comeau
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
.tex := TeX
# "bad" suffixes that shouldn't show up in listings
.pdf := BAD
.der := BAD
.cer := BAD
.crt := BAD
.0 := BAD
.exe := BAD
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
all: $(BUILD).view $(BUILD).save
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
$(REPONAME).%.cover.tex: %.cover.template.tex
	envsubst < $< > $@
%.save: %.pdf %.cover.jpg %.cover.pdf
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
	git push -u origin master
	git push -u githost master
%.pdf: %.tex
	pdflatex --shell-escape $<
$(REPONAME).%.tex: %.template.tex Makefile
	envsubst < $< > $@
$(REPONAME).kindle.%.tex: kindle.%.template.tex Makefile
	envsubst < $< > $@
$(REPONAME).paperback.%.tex: paperback.%.template.tex Makefile
	envsubst < $< > $@
%.view: %.pdf %.cover.pdf %.cover.jpg
	rm -f $+  # remove and rebuild to ensure Contents are complete
	$(MAKE) $+
	xpdf $<
	display $*.cover.jpg
%.view: %.pdf
	xpdf $<
kindle paperback:
	$(MAKE) BUILD=$(BUILD).$@ all
.PRECIOUS: %.pdf %.cover.tex %.cover.jpg
