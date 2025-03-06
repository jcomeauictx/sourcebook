FILES ?= $(wildcard ../kybyz/*.py)
test: convert
	./$< $(FILES)
clean:
	rm -f *.pdf *.aux *.log listing.tex
