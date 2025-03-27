# bashisms in Makefile, cannot use plain sh
SHELL := /bin/bash
BUILD ?= xacpi
# /var/tmp for pdfseparate
# newer Debian systems use a tmpfs /tmp, and we need space more than speed
# my files were coming out zero length, and until I ran strace, didn't know why
TMPDIR ?= /var/tmp
TIMESTAMP = $(shell date +%Y%m%d%H%M%S)
# deal with potential spaces in path names (looking at you, ghostscript)
# (better approach adapted from https://stackoverflow.com/a/67346778/493161)
# however, `--eol` sometimes returned two fields for eolattr, so am using
# format string instead
# the dot after eolinfo is to have a non-space entry for things like symlinks,
# which don't return a string. otherwise `awk` would again not have fixed
# indices for the wanted fields.
# NOTE: bonus of this approach is that min.js files typically have no line
# ending, so they will also be excluded from source printouts.
LSFORMAT := %(eolinfo:worktree). %(path)
LS := git ls-files --format='$(LSFORMAT)'
LSREPO := $(LS) | \
 awk '$$1 == "lf." {for (i=2;i<NF;i++) printf("%s%%20",$$i); print $$NF;}'
LSDIR := $(LS) ':(glob)*' | \
 awk '$$1 == "lf." {for (i=2;i<NF;i++) printf("%s%%20",$$i); print $$NF;}'
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
SUBDIRS ?= $(sort $(dir $(shell cd $(REPOPATH) && $(LSREPO))))
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
Makefile := make
README := HTML # not really, just for testing language detection
# binary font resources from casperscript that need to be skipped
# (until I figure out a better way of binary file detection)
# get language from listing path
LISTING ?=
RELPATH := $(SUBDIR)$(LISTING)
FILEPATH := $(REPOPATH)/$(SUBDIR)$(LISTING)
CAPTION := $(subst ./,,$(subst _,\_,$(RELPATH)))
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
	 $(MAKE) SUBDIR="$${subdir//%20/ }" $(BUILD).subdir >> $@; \
	done
	cat $| >> $@
%.cover.jpg: %.cover.pdf
	pdftoppm $< | ppmtojpeg > $@
%.save: %.trimmed.pdf %.cover.pdf %.cover.jpg
	mkdir -p $(HOME)/sourcebook
	cp -f $+ $(HOME)/sourcebook/
	xpdf $<
$(REPONAME).%.subdir: %.subdir.template.tex
	envsubst < $<
	for file in $$(cd "$(REPOPATH)/$(SUBDIR)"; $(LSDIR)); do \
	 $(MAKE) SUBDIR="$(SUBDIR)" LISTING="$${file//%20/ }" \
	  $(BUILD).listing; \
	done
$(REPONAME).%.listing: %.source.template.tex
	@echo 'FILEPATH: "$(FILEPATH)", CAPTION: "$(CAPTION)"' >&2
	@echo % conditionally making listing for $(FILEPATH) \($(CAPTION)\)
	@echo -n '% '
	@echo -n cd "$(dir $(FILEPATH)) && "; echo "$(LS)" "$(FILEPATH)"
	cd "$$(dirname '$(FILEPATH)')" && $(LS) "$$(basename '$(FILEPATH)')" >&2
	@echo -n '% '
	cd "$$(dirname '$(FILEPATH)')" && $(LS) "$$(basename '$(FILEPATH)')"
	@echo  # in case the above failed, don't comment out \subsection
	if [[ "$(CAPTION)" != "LICENSE" ]]; then \
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
	pdflatex -shell-escape -interaction nonstopmode "$<" || true
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
	 false; \
	fi
%.view: %.pdf %.cover.pdf %.cover.jpg
	rm -f $+  # remove and rebuild to ensure Contents are complete
	mv -f $*.log $*.$(TIMESTAMP).log  # save first run's log to analyze
	# the following inscrutable mess stolen from noosepapers, in turn
	# stolen from somewhere on stackoverflow
	set -euxo pipefail; \
	{ $(MAKE) $+ 2>&1 1>&3 3>&- | tee $(@:.view=.make.err); } \
	 3>&1 1>&2 | tee $(@:.view=.make.log)
	xpdf $<
	display $*.cover.jpg
%.view: %.pdf
	xpdf "$<"
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
# 2025-03-22 fixed broken pdfseparate using superuser.com/a/1814879/56582
# 2025-03-24 pdfunite does not work with 76000-odd pdf files, even if you
#            `ulimit -s 65536` to raise ARG_MAX sufficiently. it gave 
#            "Too many open files" and "Could not merge damaged documents"
#            errors.
# 2025-03-25 realized that all that pdfseparate/pdfunite stuff was unnecessary;
#            only need to inject clip.ps into the entire file contents.
#            see `%.trimmed.pdf` recipe
%.withborders.ps: %.ps
	sed -e '/^%%Copyright/r $(PWD)/clip.ps' $< > $@
%.ps: %.pdf
	pdftops $< $@
%.trimmed.pdf: %.withborders.ps
	ps2pdf $< $@
%.tdiff:  # compare templates to paperback
	for ttype in bookstart cover intro license sources \
	  source subdir trailer; do \
	 echo diff $*.$$ttype.template.tex paperback.$$ttype.template.tex; \
	 diff $*.$$ttype.template.tex paperback.$$ttype.template.tex; \
	done
japanese.pdf: evil\ test\ directory/japanese.tex
	pdflatex "$<"
evil: japanese.view
%.disable: | %
	# changes endlines to DOS \r\n so as to disable listings
	# CR="carriage return"
	# whirrrrr, DING! kids these days will likely never experience the
	# joy of typing on an old mechanical typewriter...
	#
	# at first made specifically for tinyseg.js, which has CJK characters
	sed -i 's/\r//' $|  # first remove any CRs so we don't double them up
	sed -i 's/$$/\r/' $|  # now add a CR at each end of line
%.reenable: | %
	# reverts %.disable
	sed -i 's/\r//' $|
%.single: | %
	# tricky when spaces in filename
	@echo 'requisite: "$|", target: "$@", prefix: "$*"' >&2
	@echo 'basename from prefix: "$(*F)"' >&2
	@echo LISTING: "$(LISTING)", REPOPATH: "$(REPOPATH)" >&2
	if [ -z "$(LISTING)" ]; then \
	 $(MAKE) LISTING="$*" REPOPATH=. SUBDIR= "$@"; \
	else \
	 filename=$$(basename "$*"); \
	 echo filename: $$filename; \
	 envsubst < singlefile.template.tex > "$$filename.single.tex"; \
	 pdflatex "$$filename.single.tex"; \
	 xpdf "$$filename.single.pdf"; \
	 true; \
	fi
# you can "comment out" any of the following by removing the ".single" suffix
singletest: \
 evil\ test\ directory/eurochars.txt.single \
#../casperscript/contrib/pcl3/doc/gs-pcl3.1.single \
#evil\ test\ directory/japanese.tex.single \
#../casperscript/zlib/ChangeLog.single \
#../casperscript/freetype/src/autofit/ft-hb.c.single \
#../casperscript/tiff/config/ltmain.sh.single \
#../casperscript/freetype/docs/reference/assets/javascripts/lunr/tinyseg.js \
# leave this line here, and you can end all the above lines with a backslash
.PRECIOUS: %.pdf %.cover.tex %.cover.pdf %.cover.jpg %.trimmed.pdf
.FORCE:
