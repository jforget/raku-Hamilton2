-*- encoding: utf-8; indent-tabs-mode: nil -*-

But
===

Le but de ce  projet est de dessiner des graphes et  de jouer avec les
chemins hamiltoniens et les plus courts chemins.

Le premier  but de  ce projet  est de  trouver des  chemins doublement
hamiltoniens dans une carte administrative. Dans un graphe connexe, un
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

Il  est  possible  d'utiliser  les  programmes  pour  d'autres  cartes
administratives, mais  il vous faudra fournir  les caractéristiques de
ces cartes.

The second  but de ce  projet est  d'examiner les plus  courts chemins
d'un sommet A à un sommet B,  ainsi que les notions associées comme le
diamètre d'un graphe et le rayon d'un graphe.

Installation
============

Vous aurez besoin de Raku, SQLite et GD, ainsi que des modules suivants :

* DBIish
* Bailador
* Template::Anti
* Inline::Perl5
* List::Util

et les modules Graph.pm et GD.pm pour Perl 5 (pas le module GD pour Raku).

Il y a  un peu de paramétrage à faire.  Notamment, vous devrez changer
le chemin  d'accès de  la base SQLite  dans `lib/db-conf-sql.rakumod`.

Utilisation
===========

Créez le fichier de base de données `Hamilton.db` avec :

```
sqlite3 Hamilton.db < cr.sql
```

Mettez à  jour le fichier `lib/db-conf-sql.rakumod`  pour y renseigner
le nom du fichier de base  de données `Hamilton.db` avec le répertoire
adéquat.

Initialisez les cartes de France avec :

```
./init-fr.raku
```

Lancez la génération des chemins hamiltoniens avec :

```
./gener1.raku --map=fr1970
./gener2.raku --map=fr1970
```

en faisant de même avec  `frreg` et `fr2015` (en évitant `gener2.raku`
pour ce dernier, car il prend trop de temps).

Pour afficher les cartes en HTML, lancez le serveur web :

```
./website.raku
```

et dans votre navigateur préféré, demandez l'adresse :

```
http://localhost:3000/
```

Vous pouvez  également utiliser les graphes  correspondant aux solides
platoniciens avec  `init-ico.raku` (dodécaèdre)  et `init-platon.raku`
(les  quatre  autres)  ou   utiliser  des  graphes  élémentaires  avec
`init-elem.raku`.

Auteur
======

Jean Forget (J2N-FORGET at orange dot fr)

Licence
=======

Les programmes sont diffusés avec la licence **Artistic License 2.0**.
Voir le texte (en anglais) dans `LICENSE-ARTISTIC-2.0`.

Les divers textes  et images de ce dépôt sont  publiés avec la licence
Creative Commons : Attribution - Partage dans les Mêmes Conditions (CC
BY-SA ).

