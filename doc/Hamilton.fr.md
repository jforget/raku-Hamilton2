-*- encoding: utf-8; indent-tabs-mode: nil -*-

Le but de ce projet est de trouver des chemins doublement hamiltoniens
dans une carte administrative. Dans un graphe connexe, un
[chemin hamiltonien](https://mathworld.wolfram.com/HamiltonianPath.html)
est un chemin qui passe une fois  et une seule par chacun des sommets.
Mais  qu'est-ce  un  chemin  _doublement_ hamiltonien  ?  Prenons  par
exemple  la  France  continentale.  Nous  enlevons  la  Corse  et  les
départements /  territoires / collectivités d'outre-mer  pour avoir un
graphe connexe.  La France se  divise en  régions et chaque  région se
divise en départements. Un chemin doublement hamiltonien est un chemin
hamiltonien  entre les  94 départements  continentaux, tel  que chaque
fois  que   le  chemin  traverse   une  région,  le  bout   de  chemin
correspondant est lui aussi hamiltonien.

La question  de déterminer  s'il existe des  chemins eulériens  sur un
graphe connexe  est simple et  bien connue. La question  de déterminer
s'il existe des chemins hamiltoniens est plus délicate, il s'agit même
d'un problème  NP-complet. Avec  94 départements, la  combinatoire est
bien  au-delà des  ressources que  j'accepte d'allouer  à un  problème
occupant  mes   loisirs.  En   imposant  la  contrainte   d'un  chemin
_doublement_ hamiltonien, la  combinatoire se réduit considérablement.
En appliquant  la technique de  « diviser pour régner », il  suffit de
déterminer les macro-chemins  hamiltoniens entre les 12  régions de la
France  continentale,  puis  pour  chaque  région  de  déterminer  les
micro-chemins  entre  les  départements  de   cette  région  (5  à  13
départements  par région,  ce  n'est  pas la  mer  à  boire), puis  de
concaténer  les  micro-chemins  en  se  basant  sur  le  canevas  d'un
macro-chemin.

Je ne me limite  pas à la carte de la France  avec les départements de
1965 et  les régions de  2015. J'envisage de  faire le même  calcul en
adoptant  le découpage  des régions  de  1970. Et  même le  cas où  je
remplace le découpage en départements  par le découpage des régions de
1970. Ce cas  de figure, avec des régions groupes  ne contenant qu'une
seule région  élémentaire, pourrait  mettre en  évidence des  bugs qui
seraient restés invisibles avec des cartes plus peuplées.

On peut envisager d'autres cartes, comme la carte mondiale de
[Risk](https://boardgamegeek.com/boardgame/181/risk)
ou celle de
[War on Terror](https://boardgamegeek.com/boardgame/24396/war-terror),
où  les régions  élémentaires  correspondent  à des  États  et où  les
régions groupes correspondent à des continents.

Le projet se base sur une base de données
[SQLite](https://sqlite.org/index.html),
des programmes
[Raku](https://raku.org/)
lancés en ligne de commande pour alimenter cette base de données et un
affichage en mode web avec des programmes Raku /
[Bailador](https://modules.raku.org/dist/Bailador:cpan:UFOBAT).

Base de données
===============

Maps
----

La  première table  est la  table `Maps`  (Cartes). Un  enregistrement
contient  juste le  code de  la  table (sans  caractère spécial,  pour
faciliter la  constitution et l'analyse  des URL) et  une description.
Elle est utilisée pour la  page d'accueil et permettre à l'utilisateur
de choisir quelle carte il veut consulter.

Areas
-----

La deuxième table, `Areas` (Zones), contient à la fois les régions
et les départements. La clé d'un enregistrement est :

* `map` le code de la carte (table `Maps`),
* `level` valant `1` pour les régions et `2` pour les départements,
* `code` permettant d'identifier la zone.

Pour un département, le code est le numéro à deux chiffres (pas trois,
parce que  les DOM ne  sont pas repris). Pour  une région de  2015, il
s'agit des trois dernières lettres du  code ISO 3166-2, tel qu'on peut
le voir
[dans cette page](https://fr.wikipedia.org/wiki/R%C3%A9gion_fran%C3%A7aise#Liste_et_codification_ISO_3166-2_des_r%C3%A9gions_actuelles).
Pour les régions de 1970, il  s'agit de codes à trois lettres inspirés
de ceux des régions de 2015. Ces codes de 1970 n'ont rien d'officiel.

Les autres informations sont :

* la désignation standard de la région ou du département,
* une longitude et une latitude approximatives,
* la couleur qui sera utilisée pour l'affichage des cartes,
* pour les départements, le code de la région d'appartenance.

Il  est prévu  deux  vues  sur cette  table,  la  vue `Big_Areas`  qui
sélectionne  le niveau  1  des  régions et  la  vue `Small_Areas`  qui
sélectionne le niveau 2 des départements.

La latitude et la longitude servent à l'affichage des cartes. Bien que
le  problème  des chemins  doublement  hamiltoniens  soit purement  un
problème de graphe  sans aucun rapport avec la  géométrie, les graphes
seront  visualisés de  telle  façon que  l'on  puisse reconnaître  les
cartes géographiques.

Borders
-------

La  table `Borders`  (Frontières) énumère  les paires  de départements
limitrophes  ou les  paires  de régions  limitrophes.  Pour un  graphe
mathématique, cela correspond aux arêtes. La clé est constituée de :

* `map` le code de la carte (table `Maps`),
* `level` valant `1` pour les régions et `2` pour les départements,
* `from_code` le code de la première zone,
* `to_code` le code de la deuxième zone.

Autres champs :

* `upper_from` le code du supérieur hiérarchique de `from`,
* `upper_to`  le code du supérieur hiérarchique de `to`,
* `longitude`,
* `latitude`.

La plupart du  temps, la longitude et la latitude  resteront à zéro et
dans  la représentation  graphique,  l'arête sera  représentée par  un
unique  segment de  droite. Dans  certains  cas, le  dessin peut  être
encombré par endroits.  Un moyen pour l'éclaircir peut  être de tracer
les arêtes avec deux segments de droite  au lieu d'un. Dans ce cas, la
longitude et  la latitude repèrent  l'endroit où les deux  segments se
joignent.

Pour  une  frontière  donnée,  il  y  aura  deux  enregistrements,  en
intervertissant `from_code` et `to_code`.

Comme pour  la table  `Areas`, il  y aura  deux vues  `Big_Borders` et
`Small_Borders` en fonction du niveau.

Tables pour les chemins : RAF

Initialisation
==============

Extraction des chemins hamiltoniens
===================================

Affichage du résultat
=====================

LICENCE
=======

Texte  diffusé sous  la licence  CC-BY-NC-ND :  Creative Commons  avec
clause de paternité, excluant l'utilisation commerciale et excluant la
modification.

Certaines illustrations  sont diffusées  avec une  licence différente.
Celle-ci est mentionnée à la suite de l'illustration.
