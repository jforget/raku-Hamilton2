-*- encoding: utf-8; indent-tabs-mode: nil -*-

But
===

Le but de ce projet est de trouver des chemins doublement hamiltoniens
dans une carte administrative. Dans un graphe connexe, un
[Hamiltonian path](https://mathworld.wolfram.com/HamiltonianPath.html)
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

Installation
============

Vous aurez besoin de Raku, SQLite et GD, ainsi que des modules suivants :

* DBIish
* Bailador
* Template::Anti
* Inline::Perl5

et le module GD pour Perl 5 (pas celui pour Raku).

Il y a  un peu de paramétrage à faire.  Notamment, vous devrez changer
le chemin  d'accès de  la base SQLite  dans `lib/db-conf-sql.rakumod`.

Utilisation
===========


Auteur
======

Jean Forget (JFORGET at cpan dot org)

Licence
=======

Les programmes sont diffusés avec la licence **Artistic License 2.0**.
Voir le texte (en anglais) dans `LICENSE-ARTISTIC-2.0`.

Les divers textes  et images de ce dépôt sont  publiés avec la licence
Creative Commons : Attribution - Partage dans les Mêmes Conditions (CC
BY-SA ).
