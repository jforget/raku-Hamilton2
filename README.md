-*- encoding: utf-8; indent-tabs-mode: nil -*-

Purpose
=======

This project  aims at drawing  graphs and having fun  with Hamiltonian
paths and shortest paths.

The original project aim was  extracting doubly Hamiltonian paths from
administrative maps. In a connected graph, an
[Hamiltonian path](https://mathworld.wolfram.com/HamiltonianPath.html)
is a  path crossing each vertex  exactly once. But what  is a _doubly_
Hamiltonian path?  Let us consider  the administrative map  of France.
France  is  split  into  _régions_,  which  are  in  turn  split  into
_départements_. For the purpose of  this project, we put aside Corsica
and overseas  regions, so the  resulting graph is connected.  A doubly
Hamiltonian path  is an Hamiltonian path  crossing each one of  the 94
departments, with  the additional  constraint that when  narrowing the
view on any single region, the partial path is still Hamiltonian.

You can  use these programmes  for other administrative maps,  but you
will have to provide the data for these maps.

The next aim  is examining the shortest  paths from node A  to node B,
plus related notions such as graph radius and graph diameter.

Installation
============

You will need Raku, SQLite and GD, plus the following modules:

* DBIish
* Bailador
* Template::Anti
* Inline::Perl5
* List::Util

and the Perl 5 Graph.pm and GD.pm modules (not the Raku GD module).

Some assembly required. After downloading  the project, you must enter
the  pathname of  the  SQLite  database in  `lib/db-conf-sql.rakumod`.

Usage
=====

Create the `Hamilton.db` database file with:

```
sqlite3 Hamilton.db < cr.sql
```

Edit  the   `lib/db-conf-sql.rakumod`  file  to  enter   the  filename
`Hamilton.db` with the proper directory name.

Initialise the French maps with:

```
./init-fr.raku
```

Generate the Hamiltonian paths with:

```
./gener1.raku --map=fr1970
./gener2.raku --map=fr1970
```

and the same  thing with `frreg` and `fr2015`  (`gener1.raku` only for
this last one, `gener2.raku` runs for too long).

Display the maps as HTML pages by running the webserver:

```
./website.raku
```

and in your favourite web browser, display the site at:

```
http://localhost:3000/
```

You  can also  use the  graphs  associated with  Platonic solids  with
`init-ico.raku` (for the dodecahedron) and `init-platon.raku` (for the
four others), or elementary graphs with `init-elem.raku`.

Author
======

Jean Forget (J2N-FORGET at orange dot fr)

License
=======

The programmes are  published under the Artistic License  2.0. See the
text in LICENSE-ARTISTIC-2.0.

The various texts  of this repository are licensed under  the terms of
Creative Commons, with attribution and share-alike (CC-BY-SA).

