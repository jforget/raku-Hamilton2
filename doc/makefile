# -*- encoding: utf-8 -*-

SHELL = /bin/sh

MD2HTML = /home/jf/.local/bin/grip
MD2HTMLOPT = --export --no-inline

.SUFFIXES:
.SUFFIXES: .md .html
.SUFFIXES: .tex .pdf

.md.html:
	$(MD2HTML) $< $(MD2HTMLOPT)
	perl -i -p -e 's/\<table\>/<table border="1">/; s/\xc2\xa0/\&nbsp;/g; s/ +\Z//;' $@

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

gr3: Lambda.png
	display $<

Lambda.png: Dodecahedron.pdf
	pdftoppm -png -f 1 -l 1 -x 240 -y 225 -W 650 -H 300 Dodecahedron.pdf Lambda
	mv Lambda-1.png Lambda.png

gr4: Kappa-Lambda-old.png
	display $<

Kappa-Lambda-old.png: Dodecahedron.pdf
	pdftoppm -png -f 1 -l 1 -x 240 -y 600 -W 1000 -H 300 Dodecahedron.pdf Kappa-Lambda-old
	mv Kappa-Lambda-old-1.png Kappa-Lambda-old.png

gr5: Kappa-Lambda-new.png
	display $<

Kappa-Lambda-new.png: Dodecahedron.pdf
	pdftoppm -png -f 1 -l 1 -x 240 -y 950 -W 1000 -H 300 Dodecahedron.pdf Kappa-Lambda-new
	mv Kappa-Lambda-new-1.png Kappa-Lambda-new.png
