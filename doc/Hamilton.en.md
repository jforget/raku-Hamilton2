-*- encoding: utf-8; indent-tabs-mode: nil -*-

This  project  aims  at   extracting  doubly  hamiltonian  paths  from
administrative maps. In a connected unoriented graph, an
[Hamiltonian path](https://mathworld.wolfram.com/HamiltonianPath.html)
is a  path crossing each vertex  exactly once. But what  is a _doubly_
Hamiltonian path?  Let us consider  the administrative map  of France.
France  is  split  into  _régions_,  which  are  in  turn  split  into
_départements_. For the purpose of  this project, we put aside Corsica
and overseas  regions, so the  resulting graph is connected.  A doubly
Hamiltonian path  is an hamiltonian path  crossing each one of  the 94
departments, with  the additional  constraint that when  narrowing the
view on any single region, the partial path is still Hamiltonian.

Checking whether  an Eulerian path  exists in  a connected unoriented graph  is a
well-known  problem. Checking  whether an  Hamiltonian path  exists is
more  difficult,   it  is  even   an  NP-complete  problem.   With  94
departments, a brute-force  approach would exceed the  resources I may
allow to  my hobbies. By  adding the _doubly_  Hamiltonian constraint,
the  size of  the  problem is  considerably  smaller. This  constraint
allows a  "divide and conquer"  approach. I  just have to  extract all
Hamiltonian macro-paths between the  12 regions in continental France,
then for each region I extract all Hamiltonian micro-paths linking the
departments  within  this  single  region (5  to  13  departments  per
region). Lastly,  I concatenate micro-paths while  following a pattern
given by a macro-path.

I do not study  only the map of France with  the departments from 1965
and the  regions from  2015. I  will do the  same experiment  with the
regions from  1970 and the  departments, ot  even with the  regions of
2015 as the big  areas and the regions of 1970 as  the small areas. In
this case,  there are several big  areas which contain only  one small
area, so this  set of data, in  which some big areas  contain only one
small  area  each,   might  trigger  a  few  bugs   which  would  stay
undiscovered with the other sets of data.

I can even think of other maps, such as the world map for
[Risk](https://boardgamegeek.com/boardgame/181/risk)
or
[War on Terror](https://boardgamegeek.com/boardgame/24396/war-terror),
in which  the small  areas are  countries (more or  less) and  the big
areas are continents. On a more local scale, we can use the map for
[Britannia](https://boardgamegeek.com/boardgame/240/britannia),
or from
[Maharaja](https://boardgamegeek.com/image/82336/maharaja).

The project uses
[SQLite](https://sqlite.org/index.html)
for storage,
[Raku](https://raku.org/)
for computations and Raku /
[Bailador](https://modules.raku.org/dist/Bailador:cpan:UFOBAT)
for display with a web browser.

Database
========

Maps
----

The first table is the `Maps` table. The record key is:

* `map` the key of the whole map (URL-friendly, no special characters).

Other fields are:

* `name` a user-intelligible designation,
* `nb_macro` the number of macro-paths for this map,
* `nb_full` the number of full paths for this map.

Areas
-----

The second table, `Areas`, contains both the regions and the departments.
The record key is:

* `map` the key of the wole map,
* `level` an integer with values `1` for regions and `2` for departments,
* `code` the last element of the key.

In France, departments  are associated with a  2-digit number (3-digit
for overseas departments, but they are out of the scope). This 2-digit
number will be used for `code`. For regions (the 2015 variant), I have
used the last 3 characters of ISO 3166-2, as seen
[on this page](https://en.wikipedia.org/wiki/ISO_3166-2:FR#First-level_metropolitan_subdivisions).
For regions (the  1970 variant), I have used  unofficial 3-letter code
similar to the codes for the 2015-variant regions.

Other fields are:

* `name` the standard designation of the region / department,
* `long` and `lat`, approximate longitude and latitude of the area,
* `color` the color used when drawing the map,
* `upper` for departments, it is the code of the region it belongs to (for regions this field is unused),
* `nb_paths` for regions, the number of regional paths (zero for departments),
* `exterior` showing whether the department is linked with another region.

Two views are defined on this table, `Big_Areas` which filters `level`
equal  to `1`  for regions  and  `Small_Areas` which  filters `2`  for
departments.

The longitude and latitude will be used to draw the maps. Although the
current problem of Hamiltonian paths is strictly a math graph problem,
with no geometry  involved, the math graphs will be  displayed in such
fashion that  the geographical  map associated can  be guessed  at and
recognised.

The  `exterior`  field  is  significant only  for  departments  (small
areas). If `1`, that means that  the department shares a border with a
department  from another  region. If  `0`,  that means  that for  this
department, all neighbour departments belong to the same region.

Borders
-------

The `Borders` table  lists the pairs of neighbour  departments and the
pairs of neighbour regions. For a math graph, the proper word would be
"edges". The key contains:

* `map` the key from table `Maps`,
* `level` with `1` for neighbouring regions and `2` for neighbouring departments,
* `from_code` for the first area,
* `to_code` for the second area.

Other fields:

* `upper_from` the code of the region for departments' edges, empty for regions' edges,
* `upper_to` similar,
* `long`,
* `lat`,
* `color`.

Most of the time,  the longitude and latitude will be  zero and in the
picture  of the  map, the  edge  will be  shown as  a single  straight
segment. In some  cases, the picture will be a  bit overcrowed in some
spots. A way  to unclutter the picture  is to draw a few  edges as two
straight segments,  bypassing the overcrowed  spot. In this  case, the
longitude and latitude define where the edge parts will join.

For a  border between two departments  in the same region,  the border
will  have the  same color  as the  region. For  a border  between two
departments belonging to different regions, the color will be `Black`.
And of course, the borders with `level` 1 will be black.

For a  given edge or border,  there will be two  `Borders` records, by
switching `from_code` with `to_code`.

As  for table  `Areas`, there  will  be two  views, `Big_Borders`  and
`Small_Borders`.

Paths
-----

The `Paths` table  stores all paths for the  various maps: macro-paths
linking  regions (big  areas), micro-paths  or regional  paths linking
departments (small  areas) belonging to  the same big area  and lastly
full paths linking all small areas. The key is:

* `map` the key from table `Maps`,
* `level` with `1` for macro-paths, `2` for regional paths and `3` for full paths,
* `area` empty for macro-paths and full paths, the code of the big area for regional paths,
* `num` a sequential number.

Other fields are:

* `path` a char string listing all areas along the path,
* `from_code` the code of the area where the path begins,
* `to_code` the code of the area where the path ends,
* `cyclic` to show if the path is cyclic,
* `macro_num` the number of the associated macro path, if there is one.

The `path`  field contains the  department codes (or region  codes for
macro-paths)  separated   by  arrows  `→`.   In  the  1970   map,  the
_Languedoc-Roussillon_ region has  two regional paths. Here  is one of
them:

```
   map         'fr1970'
   level       2
   area        'LRO'
   num         1
   path        '48 → 30 → 34 → 11 → 66'
   from_code   '48'
   to_code     '66'
   cyclic      0
   macro_num   0
```

There  is  no unique  key  constraint  on  the  `map level  area  num`
quadruplet.  This allows  us  to reorder  and  renumber the  generated
paths. The  most interesting  order is to  order them  by `from_code`,
then `to_code` and lastly by `path`,  so similar paths will be grouped
together.

The `cyclic`  column contains `1`  for cyclic  paths and `0`  for open
paths. A cyclic path is a path in which the first area shares a border
with the  last area. For  example, in the  `fr1970` map and  the `PIC`
region, the `02 →  60 → 80` is cyclic, because  it could be lengthened
to `02  → 60 → 80  → 02`. But  we keep this  path with a `80`  end. By
convention, paths  with 1 region  and 0  borders are cyclic  (e.g. the
single path in  region `IDF` in map `frreg`) and  paths with 2 regions
and  1 border  are cyclic  (e.g.  the paths  for region  `NOR` of  map
`frreg`).

The  relation between  macro-paths and  full paths  is a  0..n ↔  1..1
relation. A macro-path  can generate an unknown number  of full paths,
but  a full  path derives  from a  single macro-path.  The `macro_num`
field implements this relation.

On  the other  hand,  there  is no  relation  between macro-paths  and
regional paths.  On the  third hand, between  full paths  and regional
paths, the relation is 0..n ↔ 0..n. Hence:

Path\_Relations
---------------

This table  implements the  relation between  full paths  and regional
paths. It contains the following fields:

* `map` the key from table `Maps`,
* `full_num`, the `num` field of the full path,
* `area`, the `code` field of the region or the `area` field of the regional path,
* `region_num` the `num` field of the regional path.

Messages
--------

This  table  stores  some   informations  about  the  path  generation
processes. It will  remind the users why this or  that path generation
produced no paths. The record key is:

* `map` the key from table `Maps`,
* `dh` the datetime stamp of the message.

Other data are:

* `errcode` the code of the error,
* `area` the code of the area to which the error applies,
* `nb` the number associated with the error or the message, for example the number of generated paths.
* `data` some data giving further explanation on the error, for example the list of dead-end areas

Initialisation
==============

For copyright  reasons, I  do not provide  initialisation programmes
for  the  maps of  Risk,  War  on Terror  and  other  games. The  only
initialisation  programme is the  programme dealing  with French
regions and departments.

This  initialisation  programme  is  more complicated  than  a  normal
initialisation  programme, because  it deals  with three  hierarchical
levels  instead  of  just  two:   Y1970  regions,  Y2015  regions  and
departments.  It  initialises  three  maps  simultaneously:  `fr1970`,
`fr2015` and `frreg`.

In a  first phase,  the programme  reads a  sequential text  file with
different line types:

* `A` for Y2015 regions,
* `B` for Y1970 regions,
* `AB` for Y1970 regions which were not altered in 2015,
* `C` for departments.

Beyond the area code and the area name, lines `A` and `AB` contain the
color scheme for maps `fr2015` and `frreg`, lines `AB` and `B` contain
the color scheme for map `fr1970`.  Lines `C` contain the latitude and
longitude   for  the   individual  departments,   plus  the   list  of
neighbouring departments.

I have written the text file in the following fashion. I have displayed the
[Géo Portail](https://www.geoportail.gouv.fr/)
website   and  selected   only  the   _limites  administratives_   map
(administrative borders). For  each department, I have  clicked at the
approximate  center  of  the department,  right-clicked  and  selected
_adresse /  coordonnées du  lieu_ (location address  and coordinates).
Then I  have copied-pasted  the latitude and  longitude into  the text
file. When copying-pasting the values, I  have kept all 5 digits after
the decimal point. If you bother  to check, one latitude degree is 111
km and, at  latitude 45, one longitude  degree is 78 km.  So the fifth
decimal digit  means that the  values have  a precision of  one meter,
more or less.  This is excessive. I could have  truncated to 2 decimal
digits.

Also, I  have listed  all neighbouring departments.  In some  cases, I
have zoomed to know if two  departments are really neighbours. See for
example the  4-way point  between Vaucluse, Bouches-du-Rhône,  Var and
Alpes de Haute-Provence, at 43.72°N and 5.75°E.

Theorically, each  border between departments is  specified twice. For
example, the Var department (83) and the Vaucluse department (84) have
a  common   border.  Therefore,  the  `C ; 83`   line  should  mention
department 84 and the `C ; 84`  line should mention department 83. The
initialisation programme will check the symmetry.

During the first phase, the  departments records, that is records with
keys `fr1970`+`2` and `fr2015`+`2` are  created with all their fields.
On  the  other  hand,  in  the regions  records,  that  is  with  keys
`fr1970`+`1`, `fr2015`+`1`  `frreg`+`1` and `frreg`+`2`,  the latitude
and the longitude will not be filled, and no `Borders` records will be
created.

You  will have  to wait  for the  second phase  to finish  the regions
records. For each  region, the programme extracts  all the departments
within  this  region,  computes  the  average  of  the  latitudes  and
longitudes of  these departments  and updates  the region  record with
these computed values.

Likewise,  the  programme  creates  the `Borders`  records  with  keys
`fr1970`+`1`, `fr2015`+`1`  `frreg`+`1` and `frreg`+`2`  by extracting
all departments  borders `fr1970`+`2`  and `fr2015`+`2`  lying between
two different regions, discarding all duplicates region-wise and store
the result in the `Borders` table.

Extracting Hamiltonian Paths
============================

General Case
------------

The programme  is based on "partial  paths". A partial path  is a data
structure holding a string describing  the beginning of the path, plus
a set  holding the list  of departments not  yet visited by  the path.
This data structure is not stored in the database, it exists only when
the programme is running. In  the descriptions below, the curly braces
represent sets,  like I have  been taught  in mathematics a  long time
ago. In  this case, curly  braces have  nothing to do  with statements
blocks or with references to hashes.

Let us take the example of the Normandy region in the `fr2015` map. At
the beginning, the programme fills the list of partial paths with:

```
'14'   { 27 50 61 76 }
'27'   { 14 50 61 76 }
'50'   { 14 27 61 76 }
'61'   { 14 27 50 76 }
'76'   { 14 27 50 61 }
```

Then the programme extracts a partial  path from the list, selects all
the departments  contiguous with  the last  department of  the partial
path and still  present in the set of unvisited  departments. For each
selected department, the programme adds  this department to the string
and removes the department from the  set. Let us suppose the programme
has selected the Eure (27) partial path. The unvisited departments are
14,  50, 61  and 76.  But department  50 (Manche)  is not  adjacent to
department 27 (Eure). So the programme  uses the three others to build
new partial paths, which are stored into the list:

```
'14'        { 27 50 61 76 }
'27 → 14'   { 50 61 76 }
'27 → 61'   { 14 50 76 }
'27 → 76'   { 14 50 61 }
'50'        { 14 27 61 76 }
'61'        { 14 27 50 76 }
'76'        { 14 27 50 61 }
```

Then the programme extracts the `'27  → 76'` partial path. It tries to
find a  neighbour for  `76` within the  set of  unvisited departments:
`{ 14 50  61 }`. There are  none. So the  `'27 → 76'` partial  path is
removed from the list without being replaced.

Some time later,  after processing the `'50'`, `'50 →  61'` and `'50 →
61 → 14'` partial paths, the situation is:

```
'14'                  { 27 50 61 76 }
'27 → 14'             { 50 61 76 }
'27 → 61'             { 14 50 76 }
'50 → 14'             { 27 61 76 }
'50 → 61 → 14 → 27'   { 76 }
'50 → 61 → 27'        { 14 76 }
'61'                  { 14 27 50 76 }
'76'                  { 14 27 50 61 }
```

The programme  extracts the  `'50 → 61  → 14 →  27'` partial  path. It
checks  the list  of unvisited  departments  and finds  only one,  the
Seine-Maritime (76).  Fortunately, this  department is a  neighbour of
Eure (27). So `'76'` is added to  the string and removed from the set.
Since the  set of unvisited  departments is  an empty set,  that means
that the path `'50 → 61 → 14 →  27 → 76'` is no longer a partial path,
but a complete regional path. It is stored in the `Paths` table and it
is not inserted in the list of partial paths.

Special Case: Dead Ends
-----------------------

As we saw above, when a department is a dead-end within its region, as
Seine-Maritime (76)  is in Normandy,  you cannot find  any Hamiltonian
path  in which  this department  is  in the  middle of  the path.  The
dead-end department is always the first  or the last department in the
path.

So, to improve the speed of the path generation, instead of feeding
the list with:

```
'14'   { 27 50 61 76 }
'27'   { 14 50 61 76 }
'50'   { 14 27 61 76 }
'61'   { 14 27 50 76 }
'76'   { 14 27 50 61 }
```

the programme feeds it with only:

```
'76'   { 14 27 50 61 }
```

At the same time, the programme sets a flag to remember that each time
a regional path beginning with `'76'`  is stored into the database, it
must also store the backward path, which ends with `'76'`.

If  there are  two  dead-end  departments (in  the  `fr1970` map,  see
Languedoc-Rousillon,    but    also   Alsace,    Upper-Normandy    and
Nord-Pas-de-Calais),  the  programme takes  either  one,  it does  not
matter.

And  if  the programme  finds  three  dead-end departments,  it  stops
immediately  with  an  error  message, because  you  cannot  build  an
Hamiltonian path with three dead-ends.

So, when processing  a region, the programme  examines all departments
one after the other and counts how many neighbours this department has
in the region being processed.

Remark: the same thing applies at the upper level, when extracting the
macro-paths linking all regions.

Special Case: Isolated Departments
----------------------------------

Since the programme seeks the  departments with a single neighbour, it
can also take in account the departments with no neighbours.

If we  find a department  with no neighbours,  this can mean  that the
graph is  not connected.  It would  be the case,  for example,  with a
Britannia map where we would keep  only the ground borders and discard
the coastal links. In these  conditions, the Hebrides would not longer
be connected  with Skye and the  Orkneys would no longer  be connected
with  Caithness.  The  Scotland  10-area  graph  would  no  longer  be
connected. The programme would stop with an error message.

At the  same time, being isolated  is not automatically an  error. The
situation  arises  in   multiple  cases  in  the   `frreg`  map.  Some
Y2015-regions contain only one Y1970-region each: Britanny, Pays de la
Loire,         Centre-Val-de-Loire,          Île-de-France         and
Provence-Alpes-Côte-d'Azur. In this case, the lone Y1970-region has no
neighbours  within its  Y2015-region. Yet,  we find  a regional  path,
composed of one single node and no edge.

FIFO or LIFO?
-------------

Which method do we use to extract from the to-do list the next partial
path to process? There are several possibilities:

* The pedagogical method. Each time a partial path is extracted, it is
the  path  which  leads  to   the  most  interesting  discussion,  and
preferably  in  the  shortest  time.  How  nice!  Except  that  it  is
impossible to do on a silicon-based computer. The generation programme
does not deal with AI.

* Randomised access. It is easy  to implement, with Raku's `pick`. The
problem  is  that processes  are  no  longer reproductible,  therefore
debugging is difficult.

* FIFO access.

* LIFO access.

The  real  choice  is  limited  to  the  last  two  possibilities.  In
_Mastering Algorithms with Perl_, (I do not remember the page number),
the authors write that the good point of FIFO access (or breadth-first
searching) is that  it finds the shortest path. In  a unoriented graph
with _N_ nodes  and _E_ edges, all Hamiltonian paths  are always _N-1_
edges-long and all  Eulerian paths are always _E_  edges-long. In both
cases, finding the shortest path is pointless, so we have no reason to
use FIFO access.

Let us consider  the question more closely. If using  FIFO access, the
generation programme will generate all  1-edge partial paths and store
them into the to-do list. Then the programme will generate all 2-edges
partial paths and  store them into the to-do list,  while deleting the
1-edge partial  paths. Then  all 3-edges  partial paths  are generated
while  the 2-edges  partial paths  are deleted.  Near the  end of  the
generation, the to-do  list will contain all  _N-2_-edges long partial
paths.  And only  then, the  programme will  store the  complete paths
(_N-1_ long) into  the database and delete the partial  paths from the
in-memory to-do list.  In the case of the `fr2015`  map, with 12 nodes
and 23  edges, there are  894 complete  macro-paths. So there  were at
least 894  partial macro-paths  of length _N-2_,  all together  in the
in-memory to-do list. In fact, there were even more than that, because
the programme has generated _N-2_ paths which fail to produce complete
_N-1_ paths.  For example, you  will find many _N-2_  paths containing
the subpath `HDF  → NOR → PDL  → NAQ` but none of  these partial paths
will be able  to generate a _N-1_ path reaching  `BRE` (Britanny). All
these "unsuccessful" _N-2_  paths will be stored in the  to-do list in
addition to the 894 "successful" partial paths.

On the other  hand, when using a LIFO access,  some complete paths are
built very  early during the  process and immediately stored  into the
database. By  adding a telltale, we  can notice that for  `fr2015` the
to-do list never contains more than 25 partial paths.

The theoretical max size of the  to-do list when using LIFO access can
be computed by  studying the case of a complete  graph with _N_ nodes,
that is,  a graph in which  each one of  the _N_ nodes is  adjacent to
each one  of the  _N-1_ other  nodes. Do not  confuse this  meaning of
"complete" with the meaning of "complete path".

First, the  programme stores _N_ zero-length partial
paths. Then it removes one of them and replaces it with _N-1_ 1-length
partial paths. Then it removes one  of the 1-length paths and replaces
it with _N-2_  2-length partial paths. And so on.  The maximum size of
the to-do list  is the sum of  all numbers from _N-1_ to  _1_. With 12
nodes, that means that the theoretical maximum number is 66, way below
the number  894 which is itself  less than the actual  number of _N-2_
paths that would be stored in the to-do list if using FIFO.

Final Sort
----------

Once all  paths are created  for a given map  and a given  region, the
programmes rereads the paths, ordered  by begin area (`from_code`), by
end  area (`to_code`)  and by  path (`path`).  A sequential  number is
assigned  to  each record.  While  this  step  is  run, there  may  be
duplicate  numbers,  but  this  is  completely  temporary.  After  the
renumbering process ends, there is neither holes nor duplicates in the
number sequence.

Generating the Full Paths
=========================

The general process  is as follows. The programme  takes a macro-path,
for example `NOR → HDF → GES → etc` in the `fr2015` map. The programme
substitutes the  first region with  a regional Hamiltonian  path. This
gives `14 →  50 → 61 → 27 →  76 →→ HDF → GES →  ...`. The double arrow
shows  the last  small  area and  the first  big  area. Actually,  the
programme does not use a single Hamiltonian path from region `NOR`. It
takes all `NOR` paths, store them in its `to-do` list and extracts one
of them.

Next step. The programme selects  all small areas which are neighbours
of the last small area in the partial path (`76` aka Seine-Maritime in
the example) and that belong to the first big area in the partial path
(`HDF` or  Hauts-de-France in the  example). The programme  finds `60`
and `80` (Oise  and Somme). Then it extracts  all regional Hamiltonian
paths starting  from `60` or  `80`. The programme replaces  the region
code `HDF` by  the path, while shifting the double  arrow. The example
gives:

```
Before:
14 → 50 → 61 → 27 → 76 →→ HDF → GES → ...
After :
14 → 50 → 61 → 27 → 76 → 60 → 02 → 59 → 80 → 62 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 60 → 02 → 80 → 62 → 59 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 60 → 80 → 62 → 59 → 02 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 80 → 62 → 59 → 02 → 60 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 80 → 60 → 02 → 59 → 62 →→ GES → ...
etc.
```

Each partial path is stored into  the `to-do` list. Then the programme
takes one of them and processes the next big area.

This process may encounter dead ends.  This is the case if we continue
the example above with a `... → 62  →→ GES → ...` path. We can find no
departments which are simultaneously  neighbour of the `62` department
and belong to the  `GES` region. In this case, no  new partial path is
stored into the `to-do` list after  the previous partial path has been
removed.

The dead end  can appear a bit  later. The programme may  find a small
area neighbouring the currently final  small area, but this small area
is the starting point of no  regional Hamiltonian path. Let us suppose
we have a  path such as `... →  78 →→ NOR → ...`.  The programme finds
just one neighbouring department `27`  (Eure), but in the `NOR` region
(Normandy), no regional Hamiltonian path ever starts from `27`. So the
programme will not store any partial  path into the `to-do` list after
removing the `... → 78 →→ NOR → ...` path.

In the explanation above, I have presented the extraction of neighbour
small areas and  the extraction of regional paths as  two distinct and
successive  steps. Actually,  with the  proper SQL  join, these  steps
merge into a single step.

Optimisation
------------

Among  the partial  paths generated  in  the example  above, some  are
obviously wrong,  the paths  ending in department  `62` or  `59`. Why?
Because  the full  path must  exit the  `HDF` region  and enter  a new
region, and these two departments are not linked to any other region.

There is  an exception.  If the region  currently processed  (`HDF` in
this example) is  the last region before completion of  the full path,
then any arrival  point is valid, even an interior  department such as
`59` and `62`.

So, the  programme has two  `Select` statements. One joining  only the
`Small_Borders` view with the `Region_Paths`  view, which is used upon
arrival  at the  last region  of the  macro-path. The  second `select`
statement joins the `Small_Borders`  view with the `Region_Paths` view
as above,  plus the `Small_Areas`  view to select only  regional paths
that lead to another region.

With the  example above,  the list  of potential  paths that  would be
stored into the `to-do` list without the optimisation would be:

```
14 → 50 → 61 → 27 → 76 → 60 → 80 → 62 → 59 → 02 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 60 → 02 → 80 → 62 → 59 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 60 → 02 → 59 → 80 → 62 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 60 → 02 → 80 → 59 → 62 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 60 → 80 → 02 → 59 → 62 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 60 → 02 → 59 → 62 → 80 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 80 → 62 → 59 → 02 → 60 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 80 → 60 → 02 → 59 → 62 →→ GES → ...
```

The list of potential paths that  are actually stored into the `to-do`
list is:

```
14 → 50 → 61 → 27 → 76 → 60 → 80 → 62 → 59 → 02 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 60 → 02 → 59 → 62 → 80 →→ GES → ...
14 → 50 → 61 → 27 → 76 → 80 → 62 → 59 → 02 → 60 →→ GES → ...
```

You may  have noticed that among  these three paths, two  will fail to
progress further: the path containing `... →  80 →→ GES → ...` and the
path containing `... → 60 →→ GES → ...`, because neither `80` nor `60`
is adjacent  to the  `GES` region.  Trying to  remove these  two paths
before storing them into the `to-do`  list would need a convoluted SQL
statement, a big effort for a small result.

3 paths instead of 8 does not seem  much. Let us examine the case of a
more densely linked region, `IDF` with 800 regional Hamiltonian paths.
With this region,  we will examine a macro-path containing  `... HDF →
IDF  →  GES  ...`.  The  access from  `HDF`  is  either  through  `77`
(Seine-et-Marne) or  through `95` (Val-d'Oise)  and the exit  to `BFC`
must be from `77`.

Without optimisation, there are 104  regional paths starting from `77`
and 93 regional paths from `95`. The programme would push 197 into the
`to-do` list.

With the basic optimisation, there are  60 regional paths from `77` to
interior departments  (`75`, `92`,  `93` or  `94`), 44  regional paths
from  `77` to  exterior departments,  51 regional  paths from  `95` to
interior  departments and  42  regional paths  from  `95` to  exterior
departments. The programme will push 86 paths instead of 197.

With the advanced optimisation, the only useful regional paths are the
paths from  `95` to `77`. This  would result in pushing  only 13 paths
into  the  `to-do`  list.  This  seems  much  better  than  the  basic
optimisation, after  all. Yet, for  the moment,  I will use  the basic
optimisation.

Another point: from  reasons similar to the  generation of Hamiltonian
macro-paths  and the  generation  of Hamiltonian  regional paths,  the
`to-do` list is processed in a LIFO order, rather than FIFO.

Simplification
--------------

After splitting a SQL statement for performance purposes, I will merge
two SQL statements to simplify the programme.

Within this chapter, I will deal  with the `fr2015` map (12 big areas)
and a `NOR →  HDF → GES → etc` macro-path as  an example, plus another
case with  an unnamed map  containing a  single big area  (which means
also a single macro-path). To deal with these two cases, the programme
needs four loops:

### Step 1 for `fr2015`

A  loop selects  the  regional paths  while taking  care  of exit  and
disregarding entry:

```
select xxx
from Region_Paths        B
join with Small_Regions  C
   on  C.map      = B.map
   and C.code     = B.to_code
   and C.exterior = 1
where B.map  = ?
where B.area = ?
```

The first region  is replaced by its regional path,  a double arrow is
inserted between the first region's  path and the second region's code
and the result is stored into the `to-do` list.

### Steps 2 to 11 for `fr2015`

The loops selects  regional paths while taking care of  both entry and
exit.

```
select xxx
from Small_Borders     A
join with Region_Paths B
   on  B.map  = A.map
   and B.area = A.upper_to
join with Small_Areas  C
   on  C.map      = B.map
   and C.code     = B.to_code
   and C.exterior = 1
where A.map       = ?
and   A.from_code = ?
```

The  programme slides  the double  arrow past  the current  region and
replaces this region by its regional  paths. The result is stored into
the `to-do` list.

### Step 12 for `fr2015`

The  loop  selects regional  paths  while  taking  care of  entry  and
disregarding exit.

```
select xxx
from Small_Borders        A
join with Region_Paths    B
   on  B.map  = A.map
   and B.area = A.upper_to
where A.map       = ?
and   A.from_code = ?
```

The last region is replaced by  its regional path, the double arrow is
removed and the full path is written into the `Paths` table.

### Single Step for a Single-Region Map

The loop selects the regional  paths while disregarding both entry and
exit.

```
select xxx
from Region_Paths B
where B.map = ?
```

The full path is immediately written into the `Paths` table. Actually,
in the  special case of  a single-region  map, the generation  of full
paths  is just  duplicating regional  paths to  full paths  with minor
alterations, such as the value of the `level` field.

### Refactoring

The trick consists  in adding a "zero step" involving  a virtual small
area `*`, which is  linked to all small areas on  the map. And instead
of  processing  the `NOR  →  HDF  → GES  →  etc`  path, the  programme
processes the `* →→  NOR → HDF → GES → etc` path.  In this way the "do
not pay attention to the entry" clause  on step 1 is equivalent to the
"be sure to link with the `*` virtual department". There is no need to
insert a double  arrow, it has already been inserted  in step zero, we
need just  to slide it  like in  steps 2 to  11. The virtual  area `*`
appears  only  in the  `Borders_With_Star`  view,  that will  be  used
instead of the `Small_Borders` in all SQL statements above.

The  `Borders_With_Star` view  also allows  us  to merge  step 12  for
`fr2015` with the  single step for a one-region map.  During this last
step, we remove the `* →` prefix that was added in step 0.

Adding a new small area `*`  does not change the generated full paths.
Since no macro-paths include the `*` virtual region which contains the
`*` virtual  small-area, there is no  risks that a full  path would be
diverted to the `*` small area.

The   virtual   small   area   `*`    appears   only   in   the   view
`Borders_With_Star`. It appears in no other views and in no tables. In
addition,  the borders  between `*`  and another  area are  single-way
borders, while  all other borders  are two-way borders. The  reason is
that we do not  need to go back from a real small  area to `*`, we can
keep the `Borders_With_Star` simple.

Displaying the Results
======================

I have already explained in a
[previous project](https://github.com/jforget/Perl6-Alpha-As-des-As-Zero/blob/master/Description/description-en.md#user-content-templateanti)
that I do not like templating modules. The only templating module I like is
[`Template::Anti`](https://modules.raku.org/dist/Template::Anti:cpan:HANENKAMP),
because its templating language is vanilla HTML, without any extension
and without  any specific syntax.  So I used `Template::Anti`  in this
project.

The  project  includes also  a  graphic  component. My  preference  to
programmatically generate graphics is the
[Metapost](https://www.tug.org/metapost.html)
interpreter embedded inside the
[LuaL<sup>A</sup>T<sub>E</sub>X](http://luatex.org/)
programme. In this case, I do not see how
LuaL<sup>A</sup>T<sub>E</sub>X can integrate with a web server.

Plan B is using the
[GD](https://linux.die.net/man/3/gd)
library. Fortunately, there is a
[GD module for Raku](https://github.com/raku-community-modules/GD).
Unfortunately, this  module misses  many features, including  two that
are essential to my project: displaying some text within the graphics,
and  changing the  thickness  when drawing  lines,  features that  are
available in the
[Perl 5 version of the GD module](https://metacpan.org/pod/GD).

The final solution is to use
[Inline::Perl5](https://modules.raku.org/dist/Inline::Perl5:cpan:NINE),
which allows using Perl 5 modules in Raku programmes.

Because of  the expected number  of Hamiltonian paths,  generating all
graphic representations for all Hamiltonian  paths and storing them in
permanent files  is a big no-no.  The Hamiltonian paths are  stored as
character strings  inside the database,  that is enough.  Graphics are
generated on the fly when browsing the website. They are not stored in
temporary files, they are directly inserted in HTML source after being
encoded with
[MIME::Base64](https://modules.raku.org/dist/MIME::Base64:zef:zef:raku-community-modules).

Website Organisation
--------------------

The  website is  bilingual  and  can scale  easily  to a  multilingual
status. For  the moment,  only English and  French are  available. The
language code is the first element of the URLs.

The front page  is nothing more than the liste  of all available maps.
By default, it is displayed in  English, but by typing the proper URL,
you can have the list in French.

For each map, we have:

* The full map with all its departments. URL
http://localhost:3000/en/full-map/fr2015

* The full map, showing a full path. URL
http://localhost:3000/en/full-path/fr2015/2

* The reduced map, or macro-map, with only the regions. URL
http://localhost:3000/en/macro-map/fr2015

* The reduced map, showing a macro-path. URL
http://localhost:3000/en/macro-path/fr2015/2

* A regional map, showing all departments inside a region, plus all
neighbouring departments. URL
http://localhost:3000/en/region-map/fr2015/HDF

* A regional map with a regional path. URL
http://localhost:3000/en/region-map/fr2015/HDF

* A regional map with a (truncated) full path. URL
http://localhost:3000/en/region-with-full-path/fr2015/HDF/3

A Few Remarks
-------------

### What is the projection used when building the maps?

According to [xkcd](https://xkcd.com/977/), this is the "plate-carrée"
(or "equirectangular")  transformation. In  a first  step, I  take the
longitude and latitude  values and I use them  directly as rectangular
coordinates.  This gives  some  shrinking at  low  latitudes and  some
stretching at  high latitudes.  One longitude degree  is 81 km  in the
South of  France and only 70 km  in the North of  France, but latitude
degrees are  not altered. This distorsion  is much less than  what you
get with the Mercator projection at high latitudes.

In  a second  step, the  geographical dimensions  are adjusted  to the
canvas  dimensions,  that  is,  1000 × 1000  pixels.  For  continental
France, which  is 950 km in the  E-W direction and 1000 km  in the N-S
direction, there is no distorsion, because  the scale is about 1 pixel
per km in both directions. This  is different with, say, Britanny. The
four  points  showing Britanny  are  separated  by  63 km in  the  N-S
direction and by 172 km  in the E-W direction (if I  had used the real
geographical maps,  showing the  full extent of  the 4  departments, I
would have found 152 km N-S and  273 km E-W). The distorsion is higher
than  previously,  because  the  scale  is 6  pixels  per  km  in  the
horizontal  direction and  about  16  pixels per  km  in the  vertical
direction.

Actually, I  have decided to  add a  vertical scale and  an horizontal
scale in the  map drawings. They were not part  of the initial design,
but I think it has some usefulness.

### Why do the region maps show the neighbouring departments?

The first  reason is  displaying a  full path in  a region.  Since the
neighbouring departments are displayed, we  can show how the full path
enters  the  region   and  how  it  exits  the   region.  Without  the
neighbouring  departments, the  graphics would  have been  exactly the
same  as displaying  a region  path  strictly within  said region.  In
addition,  with visible  neighbouring departments,  it is  possible to
specify an `imagemap` with hyperlinks to neighbouring regions.

The second reason is the coordinates  distorsion I have shown above. I
have taken the example of Britanny.  I could have taken the example of
Nord-Pas-de-Calais   or   Haute-Normandie   in   the   `fr1970`   map.
Nord-Pas-de-Calais contains only two  departments, nearly aligned on a
E-W horizontal  line. The vertical  gap is  0.21° or 23 km,  while the
horizontal gap  is 1.3°, that is,  92 km. Yet, because of  the way the
coordinates adjustment is  computed, both points would  be on opposite
corners of the canvas  and the scale would be 43 pixels  per km on the
vertical direction and  11 pixels per km on  the horizontal direction.
By adding the  neighbouring Somme and Aisne, the  vertical gap extends
to  0.82° or  91 km, which  gives  11 pixels  per km  on the  vertical
direction. In this case, the distorsion is nearly eliminated. In other
cases, it is just reduced.

For Haute-Normandie, the two departments are aligned on a N-S vertical
line. The horizontal gap is only  0.05° or 3.62 km, while the vertical
gap  is  0.59° or  65.5 km.  So  the scale  would  be  216 pixels  per
horizontal km and 15 pixels per vertical km.

There  is worse.  There is  the  `frreg` map,  with the  Y2015-regions
Britanny,  Île-de-France,  Centre-Val-de-Loire,  Pays-de-la-Loire  and
Provence-Alpes-Côte-d'Azur.   Each   of   them   contains   only   one
Y1970-region. The max  longitude and the min longitude  are equal, and
the same thing  happens with latitudes. In this  case, the coordinates
adjustment triggers two divisions zero-on-zero. By adding neighbouring
Y1970-regions, the divisions by zero are avoided.

### About the average longitude and the average latitude

Giving to a big  area a longitude and a latitude  equal to the average
longitude and latitude  of the small areas inside seems  to be a smart
thing to do. But could this produce some glitches?

In theory, yes. With the actual maps, no. At least for the French maps.

With a rigid  mathematical point of view, no area  is a convex domain.
The border  is always  zigzagging at  one point  or at  another, which
prevents the  area from being convex.  The only exceptions I  know are
Colorado and Wyoming in the USA.  Yet, we can consider that some areas
are nearly convex  and others are definitely concave.  See for example
Cantal  and Moselle.  Each  one  has an  inward  "dent"  that is  more
important than  in any other  department. If  this dent was  even more
important, it could happen that the geometric centre of the department
would be in this dent, that is, outside the department's borders.

With the method I used to  initialise the longitudes and latitudes for
the departements, it  could not happen. Even with a  very long dent, I
would have chosen a point within the department. But if a region had a
dent similar in proportions to Cantal's or Moselle's dent, the average
longitude and the average latitude could have placed the centre of the
region inside the  dent and outside the region's borders.  This is not
the case  with the French regions  (both the Y1970 ones  and the Y2015
ones).

On the other hand, it happens with
[Maharadjah](https://boardgamegeek.com/image/82336/maharaja),
if we includes the three sea areas  and the six foreign areas as a sea
region and  a foreign region.  The average latitude and  longitude for
the sea  areas could place the  sea region within South  India and the
average latitude and the average  longitude of the foreign areas could
place the foreign region within North India.

This is even worse with
[Britannia](https://boardgamegeek.com/image/5640409/britannia-classic-and-new-duel-edition),
if we decide  to keep the sea  areas and group them into  a single sea
region. Since the sea areas are all around Great Britain, the computed
centre of  the region will  most certainly be  near the centre  of the
map, well within the borders of England.

In the  programmes which  load the Maharadjah  data and  the Britannia
data into the database, I could have  coded a special case for the sea
regions. I did not do it. I  am fine with a macro-map showing a glitch
when displaying the sea region in a wrong place.

### Why the dots on the region borders?

For  most  people,  the   borders  between  departments  belonging  to
different  regions are  black, while  the borders  between departments
belonging to the same region  are coloured. Colour-blind people cannot
rely  on this  difference. So  the  dots allow  them to  differentiate
between both kinds of borders.

### Performances

While  running the  `gener1.raku` programme  on the  Britannia map,  I
faced a big problem when generating the Hamiltonian regional paths for
England (20  areas and 40  inner borders, that  is, 80 records  in the
`Borders`  table).  Usually,  the  `gener1.raku`  programme  writes  a
progress message with  a timestamp every 100 complete  paths and every
10000 partial paths. When generating paths for England, I noticed that
the delay between  two messages was increasing. At the  same time, the
task manager on my computer was  showing that the percentage of active
memory was steadily increasing. A memory leak!

After  some  checking,   I  found  the  reason.  There   is  a  `begin
transaction`  when the  programme  begins processing  a  region and  a
`commit` when this  processing ends. To keep the size  of the database
journal low, there  is also a `commit` immediately  followed by `begin
transaction` every 100 complete paths.  Because of an error, there was
also  a  `commit`  +  `begin  transaction`  each  time  the  programme
processed  a partial  path.  The English  Hamiltonian path  generation
would produce 16_182 complete paths after processing 3_562_769 partial
paths. So there were more than 3 millions commits instead of just 162.

I removed the superfluous `commit`  + `begin transaction`. The leak is
not plugged, but it happens 162 times instead of 3 millions, so it has
no visible effects.

License
=======

This  text is  licensed  under  the terms  of  Creative Commons,  with
attribution and share-alike (CC-BY-SA).

