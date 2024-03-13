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
	pdftoppm -png -f 2 -l 2 -x 240 -y 225 -W 650 -H 300 Dodecahedron.pdf Lambda
	mv Lambda-2.png Lambda.png

gr4: Kappa-Lambda-old.png
	display $<

Kappa-Lambda-old.png: Dodecahedron.pdf
	pdftoppm -png -f 2 -l 2 -x 240 -y 600 -W 1000 -H 300 Dodecahedron.pdf Kappa-Lambda-old
	mv Kappa-Lambda-old-2.png Kappa-Lambda-old.png

gr5: Kappa-Lambda-new.png
	display $<

Kappa-Lambda-new.png: Dodecahedron.pdf
	pdftoppm -png -f 2 -l 2 -x 240 -y 950 -W 1000 -H 300 Dodecahedron.pdf Kappa-Lambda-new
	mv Kappa-Lambda-new-2.png Kappa-Lambda-new.png

gr6: Kappa-Lambda-after.png
	display $<

Kappa-Lambda-after.png: Dodecahedron.pdf
	pdftoppm -png -f 2 -l 2 -x 240 -y 1300 -W 300 -H 300 Dodecahedron.pdf Kappa-Lambda-after
	mv Kappa-Lambda-after-2.png Kappa-Lambda-after.png

gr7: Kappa-Lambda-arrays.png
	display $<

Kappa-Lambda-arrays.png: Dodecahedron.pdf
	pdftoppm -png -f 1 -l 1 -x 250 -y 250 -W 830 -H 740 Dodecahedron.pdf Kappa-Lambda-arrays
	mv Kappa-Lambda-arrays-1.png Kappa-Lambda-arrays.png

gr8: HDF-to-OCC-a.png
	display $?

HDF-to-OCC-a.png: HDF-to-OCC.pdf
	pdftoppm -png -f 1 -l 1 -x 130 -y 220 -W 1060 -H 380 $< HDF-to-OCC
	mv HDF-to-OCC-1.png HDF-to-OCC-a.png

HDF-to-OCC-b.png: HDF-to-OCC.pdf
	pdftoppm -png -f 1 -l 1 -x 130 -y 640 -W 1060 -H 380 $< HDF-to-OCC
	mv HDF-to-OCC-1.png HDF-to-OCC-b.png
