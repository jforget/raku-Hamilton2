# -*- encoding: utf-8 -*-

SHELL = /bin/sh

MD2HTML = /home/jf/.local/bin/grip
MD2HTMLOPT = --export --no-inline

.SUFFIXES:
.SUFFIXES: .md .html
.SUFFIXES: .tex .pdf

.md.html:
	$(MD2HTML) $< $(MD2HTMLOPT)
	perl -i -p -e 's/\<table\>/<table border="1">/; s/\xc2\xa0/\&nbsp;/g' $@

.tex.pdf:
	lualatex $<

target: Hamilton.fr.html Hamilton.en.html

gr1: Elementary-graphs.png
	display $<

Elementary-graphs.png: Elementary-graphs.pdf
	pdftoppm -png -f 1 -l 1 -x 240 -y 225 -W 700 -H 700 Elementary-graphs.pdf Elementary-graphs
	mv Elementary-graphs-1.png Elementary-graphs.png

gr2: Special-graphs.png
	display $<

Special-graphs.png: Special-graphs.pdf
	pdftoppm -png -f 1 -l 1 -x 240 -y 225 -W 780 -H 400 Special-graphs.pdf Special-graphs
	mv Special-graphs-1.png Special-graphs.png
