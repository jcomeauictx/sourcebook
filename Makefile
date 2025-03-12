REPONAME ?= kybyz
BOOKTITLE ?= $(REPONAME)
AUTHOR ?= lotecnotec press
FILES ?= $(shell cd ../$(REPONAME) && git ls-files)
PARTS := $(REPONAME).bookstart.tex $(REPONAME).intro.tex \
 $(REPONAME).trailer.tex
ifeq ($(SHOWENV),)
	# not exporting all globals---but at least those needed by templates
	export REPONAME AUTHOR BOOKTITLE
else
	export
endif
all: $(REPONAME).view
$(REPONAME).tex: $(PARTS)
	cat $+ > $@
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
