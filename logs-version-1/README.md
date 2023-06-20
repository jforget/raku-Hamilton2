-*- encoding: utf-8; indent-tabs-mode: nil -*-

This directory  contains log files  for building Hamiltonian  paths in
the French  maps `frreg`, `fr1970`  and `fr2015` and in  the Britannia
and Maharaja maps.

The `xxx-1.log` files contain the building of macro-paths and regional
paths and  the `xxx-2.log` files  contain the building of  full paths.
You  may notice  that in  some logfiles,  the renumbering  of regional
paths is not logged, that was  an earlier version of the `gener1.raku`
programme. Looking through the history is  left as an exercice for the
reader.

The  `gener2.raku`  programme  is  the version  using  the  `exterior`
optimisation, not the `where exists (select 'x'...)`.

Ce  répertoire contient  les fichiers  traces pour  la génération  des
chemins hamiltoniens, pour les  cartes françaises `frreg`, `fr1970` et
`fr2015` ainsi que pour les cartes de Britannia et de Maharadjah.

Les fichiers  `xxx-1.log` donnent  les traces  pour la  génération des
macro-chemins  et des  chemins régionaux  et les  fichiers `xxx-2.log`
donnent les traces pour la génération des chemins complets. Comme vous
pourrez le remarquer, certains fichiers `xxx-1.log` datent de l'époque
où   le   programme   `gener1.raku`  n'affichait   rien   pendant   la
renumérotation des  chemins. La  recherche dans l'historique  de cette
version  de  `gener1.raku` est  laissée  à  titre d'exercice  pour  le
lecteur.

Pour  le   programme  `gener2.raku`,  la  version   utilisée  dans  ce
répertoire  est   la  version  légèrement  optimisée   avec  le  champ
`exterior`,  pas la  version optimisée  avec la  clause `where  exists
(select 'x'...)`.
