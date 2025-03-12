REPONAME ?= kybyz
BOOKTITLE ?= $(REPONAME)
AUTHOR ?= lotecnotec press
FILES ?= $(shell cd ../$(REPONAME) && git ls-files)
PARTS := $(REPONAME).bookstart.tex $(REPONAME).intro.tex \
 $(REPONAME).sources.tex
FINAL_PART := $(REPONAME).trailer.tex
SUFFIXES := .py .mk .tex
SUFFIX_LANGUAGES := Python make TeX
BASENAMES := Makefile
BASENAME_LANGUAGES := make
ifeq ($(SHOWENV),)
	# not exporting all globals---but at least those needed by templates
	export REPONAME AUTHOR BOOKTITLE LANGUAGE LISTING
else
	export
endif
all: $(REPONAME).view
$(REPONAME).tex: $(PARTS) | $(FINAL_PART)
	cat $+ > $@
	cat $| >> $@
test: convert
	./$< $(FILES)
clean:
	rm -f *.aux *.log *.toc listing.tex overleaf_book.pdf *.lua *.out
	rm -rf _markdown_$(REPONAME)
distclean: clean
	rm -f $(REPONAME).pdf $(REPONAME).*.tex $(REPONAME).tex
env:
ifeq ($(SHOWENV),)
	$(MAKE) SHOWENV=1 $@
else
	$@
endif
push:
	git push -u origin master
	git push -u githost master
%.pdf: %.tex
	pdflatex --shell-escape $<
$(REPONAME).%.tex: %.template.tex Makefile
	envsubst < $< > $@
%.view: %.pdf
	xpdf $<
