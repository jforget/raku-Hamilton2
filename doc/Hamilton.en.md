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

(On the right, zomm on Île-de-France, which is too much cluttered on the left side of the picture)

![Example with French departments and year 1970 regions](fr1970-1.png)

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

Note: for copyright reasons, I do  not give the Britannia and Maharaja
maps  in   this  repository.  Yet,   I  will  mention  these   in  the
documentation below. If necessary, you  can access the links above and
find the maps.

The project uses
[SQLite](https://sqlite.org/index.html)
for storage,
[Raku](https://raku.org/)
for computations and Raku /
[Bailador](https://modules.raku.org/dist/Bailador:cpan:UFOBAT)
for display with a web browser.

A Few Words about Graph Theory
==============================

Unless  explicitly  mentioned, I  will  restrict  these paragraphs  to
finite connected undirected graphs.

A graph  consists of  vertices (also  known as  nodes) and  edges, but
because of  the underlying reality,  I will  also use the  words areas
(regions and departments) and borders.

The degree of a vertex is the  number of edges coming from the vertex.
If the degree  of a vertex is 1,  I will call this vertex  a dead end.
Examples are  the Nord-Pas-de-Calais  region in  the 1970  French map,
linked only  to Picardy,  or the Pyrénées-Atlantiques  department (64)
within the Aquitaine region (in 1970) or the Nouvelle Aquitaine region
(in 2015),  this department  being linked only  to Landes  (40), since
departments 32 and 64 are irrelevant.

![Top of the fr1970 macro-map and South of Nouvelle Aquitaine](NPC-PIC-NAQ.png)

According to the
[Glossary of graph theory](https://en.wikipedia.org/wiki/Glossary_of_graph_theory)
the phrase "dead end" is not an official phrase for graph theory.
On the other hand, I found a convenient notion, the
[Articulation point](https://en.wikipedia.org/wiki/Articulation_point).

Within  a connected  graph, an  articulation point  is a  vertex which
ensures the  graph is  connected. In  other words,  if we  remove this
vertex and  its edges,  the graph  is no  longer connected.  Using the
examples above,  the Picady region  within the  1970 French map  is an
articulation point,  because if it is  removed, the Nord-Pas-de-Calais
region  is no  longer linked  to any  remaining region.  Likewise, the
Landes (40) department  is an articulation point,  because if removed,
the  Pyrénées-Atlantiques  department is  no  longer  linked to  other
departments within the Aquitaine / Nouvelle Aquitaine region.

Articulation points are not always  associated with dead ends. See for
example the Maine-et-Loire department  in the Pays-de-la-Loire region.
If removed,  the region  is split into  two connected  components, one
with Loire-Atlantique  (44) and  Vendée (85),  the other  with Mayenne
(53) and Sarthe (72).

![Pays de la Loire](Pays-de-la-Loire.png)

You  can easily  notice that  if a  graph contains  a dead  end, every
Hamiltonian path will  either start from this dead end  or stop at it.
On  the other  hand, if  a graph  contains an  articulation point,  no
Hamiltonian  path   will  start  from  this   articulation  point,  no
Hamiltonian path will stop at it.

The  articulation  point  notion  is  interesting  for  human-to-human
discussions   (like   this   documentation    file),   but   not   for
human-to-computer discussions. In other words, the articulation points
are not implemented in the programmes from this project.

There is  a similar notion for  edges, the "bridges". In  the examples
above, the `NPC` to `PIC` edge and the `64` to `40` edges are bridges.
There are no bridges in the "Pays  de la Loire" region. I did not need
this notion in my programmes or in my documentation.

An interior border  is a border between two  departments (small areas)
belonging  to the  same region  (big area).  An exterior  border is  a
border between  two departments belonging  to different regions.  I do
not  care  about  foreign  countries such  as  Belgium  or  Luxemburg.
Likewise, an interior area is a  small area with only interior borders
and  an exterior  area is  a  small area  with at  least one  exterior
border.  Thus, in  the  `fr2015`  map, department  `60`  (Oise) is  an
exterior department, linked  to two departments from  Normandy and two
departments  from  Île-de-France  and  department `59`  (Nord)  is  an
interior department, although adjacent to Belgium.

Another  interesting  notion  is Hamiltonian  cycles.  In  Hamiltonian
cycles, the end node  is the same as the begin  node, which means that
it is visited twice.  For example, The `29 → 56 → 35  → 22 → 29` cycle
in the Bretagne region. In my  project, this cycle will be represented
by a path omitting the last step, that  is, `29 → 56 → 35 → 22`. There
will be  a boolean  column in  the `Paths`  table and  a parenthesized
mention in the web pages, nothing more.

![Bretagne](Bretagne.png)

You may consider  that the cycle `22 →  29 → 56 → 35 →  22`, the cycle
`35 → 22 →  29 → 56 → 35` and the  cycle `56 → 35 → 22 →  29 → 56` are
the same as cycle `29 → 56 → 35  → 22 → 29`. In my project, there will
be four different paths `29 → 56 → 35  → 22`, `22 → 29 → 56 → 35`, `35
→ 22  → 29 → 56`  and `56 →  35 → 22 →  29` for this cycle,  plus four
other, running along the cycle in the opposite direction.

When I  read texts about  graphs, I notice  that most often  they deal
with Hamiltonian cycles and they ignore Hamiltonian paths. This is not
the opposite here,  I deal with Hamiltonian paths and  I nearly ignore
Hamiltonian cycles.

Database
========

Maps
----

The first table is the `Maps` table. The record key is:

* `map` the key of the whole map (URL-friendly, no special characters).

Other fields are:

* `name` a user-intelligible designation,
* `nb_macro` the number of macro-paths for this map,
* `nb_full` the number of full paths for this map,
* `nb_generic` field described in the
[fourth version of the software](#user-content-fourth-attempt).
* `specific_paths` boolean field also described in the
[fourth version of the software](#user-content-fourth-attempt).
* `fruitless_reason` field described in the
[fifth version of the software](#user-content-fifth-version),
* `with_scale` flag controlling the display  of a scale in the various
pictures,  meaning  that the  graph  nodes  are locations  on  Earth's
surface,
* `with_isom` flag showing whether  isometries have been generated for
the graph,
* `full_diameter`,
* `full_radius`,
* `macro_diameter`,
* `macro_radius`.

Fields `full_diameter`, `full_radius`, `macro_diameter` and `macro_radius`
are described in the
[chapter](#user-content-statistics-on-shortest-paths)
about "shortest paths statistics".

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
For regions (the 1970 variant),  I have used unofficial 3-letter codes
similar to the codes for the 2015-variant regions.

Other fields are:

* `name` the standard designation of the region / department,
* `long` and `lat`, approximate longitude and latitude of the area,
* `color` the color used when drawing the map,
* `upper` for departments, it is the code of the region it belongs to (for regions this field is unused),
* `nb_macro_paths`,
* `nb_macro_paths_1`,
* `nb_region_paths`,
* `exterior` showing whether the department is linked with another region,
* `diameter`,
* `radius`,
* `full_eccentricity`,
* `region_eccentricity`.

Two views are defined on this table, `Big_Areas` which filters `level`
equal  to `1`  for regions  and  `Small_Areas` which  filters `2`  for
departments.

The longitude and latitude will be used to draw the maps. Although the
current problem of Hamiltonian paths is strictly a math graph problem,
with no geometry  involved, the math graphs will be  displayed in such
fashion that  the geographical  map associated can  be guessed  at and
recognised. If `Maps.with_scale` is  false, the longitude and latitude
are nothing more than numeric coordinates to generate the picture.

The  `nb_region_paths`  field  has  two different  meanings,  one  for
regions and  the other  for departments.  For a  region, it  holds the
total  number  of Hamiltonian  regional  paths  generated within  this
region. For a department, it is  the number of regional paths starting
from or stopping at this department.

For  regions,  the `nb_macro_paths`  field  has  the same  meaning  as
`nb_region_paths`  for departments,  it is  the number  of Hamiltonian
macro-paths starting from or stopping at this region. For departments,
this field is zero.

The `nb_macro_paths_1`  field also counts the  Hamiltonian macro-paths
starting from or  stopping at this region, but in  this case, only the
macro-paths which  generated full  Hamiltonian paths are  counted. For
departments, this field is zero.

The  `exterior`  field  is  significant only  for  departments  (small
areas). If `1`, that means that  the department shares a border with a
department  from another  region. If  `0`,  that means  that for  this
department, all neighbour departments belong to the same region.

Fields  `full_eccentricity`,   `region_eccentricity`,  `diameter`  and
`radius` are described in the
[chapter](#user-content-statistics-on-shortest-paths)
about "shortest paths statistics".

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
* `long`, an optional longitude,
* `lat`, an optional latitude,
* `color`,
* `fruitless`,
* `nb_paths`,
* `nb_paths_1`.
* `cross_idl`

In some cases, a record in this table does not represent a terrestrial
border proper, but a sea lane from  an area to another area on another
island / continent. But we keep  the geographical word "border" or the
mathematical word "edge".

If the map covers the whole Earth,  it may happen that some edges link
a far-east area  on the map right  side to a far-west area  on the map
left  side. The  `cross_idl`  field is  set to  `1`  so the  graphical
routine will deal  with this special case.  "idl" means "International
Date Line", even if in some cases the map is not cut along this line, like in
[this example]s(https://boardgamegeek.com/image/476132/risk).

Most of the time,  the longitude and latitude will be  zero and in the
picture  of the  map, the  edge  will be  shown as  a single  straight
segment. In some  cases, the picture will be a  bit overcrowed in some
spots. A way  to unclutter the picture  is to draw a few  edges as two
straight segments,  bypassing the overcrowed  spot. In this  case, the
longitude and latitude define where the edge parts will join.

Among  France's  departments,  the  only  problem  is  the  edge  from
Seine-et-Marne (77) to  Val-d'Oise (95). If drawn as  a straight line,
this edge may be masked by the Seine-Saint-Denis department (93). So I
had to add a waypoint a little northward of the direct line.

![Map of Île de France](Ile-de-France.png)

For a  border between two departments  in the same region,  the border
will  have the  same color  as the  region. For  a border  between two
departments belonging to different regions, the color will be `Black`.
And of course, the borders with `level` 1 will be black.

For a  given edge or border,  there will be two  `Borders` records, by
switching `from_code` with `to_code`.

For  a level-1  border, the  `nb_paths` field  contains the  number of
Hamiltonian macro-paths using this border (or the reverse border). For
a  level-2  border, this  field  contains  the number  of  Hamiltonian
regional  paths containing  this border  or its  reverse. For  level-2
borders  between departments  from  different regions,  this field  is
zero.

The  `nb_paths_1`  field  also  contains  the  number  of  Hamiltonian
macro-paths  using  this  border,   but  only  the  macro-paths  which
generated  full paths  are counted.  This  field is  zero for  level-2
borders.

As  for table  `Areas`, there  will  be two  views, `Big_Borders`  and
`Small_Borders`.

The use and meaning of `fruitless` will be explained in the
[third version of the software](#user-content-third-attempt).

Paths
-----

The `Paths` table  stores all paths for the  various maps: macro-paths
linking  regions (big  areas), micro-paths  or regional  paths linking
departments (small  areas) belonging to  the same big area  and lastly
full paths linking all small areas. The key is:

* `map` the key from table `Maps`,
* `level` with `1` for macro-paths, `2` for regional paths, `3` for full paths and `4` for generic regional paths,
* `area` empty for macro-paths and full paths, the code of the big area for regional paths,
* `num` a sequential number.

Other fields are:

* `path` a char string listing all areas along the path,
* `from_code` the code of the area where the path begins,
* `to_code` the code of the area where the path ends,
* `cyclic` to show if the path is cyclic,
* `macro_num` the number of the associated macro path, if there is one,
* `fruitless`,
* `fruitless_reason`,
* `nb_full_paths`,
* `generic_num`,
* `first_num`,
* `paths_nb`,
* `num_s2g`.

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
region, the `02 →  60 → 80` is cyclic, because  it could  be  extended
to `02  → 60 → 80  → 02`. But  we keep this  path with a `80`  end. By
convention, paths  with 1 region  and 0  borders are cyclic  (e.g. the
single path in  region `IDF` in map `frreg`) and  paths with 2 regions
and  1 border  are cyclic  (e.g.  the paths  for region  `NOR` of  map
`frreg`).

The use and meaning of `fruitless` and `fruitless_reason` will be explained in the
[third version of the software](#user-content-third-attempt).

The  field `nb_full_paths`  is  significant only  for macro-paths.  It
contains the number  of full paths derived from  this macro-path. This
field could contain  a significant value for regional  paths also, but
there is no efficient way to compute  this value, so the field will be
zero for regional paths.

Generic   regional   paths  (`level=4`)   and   the   use  of   fields
`generic_num`, `first_num`, `paths_nb` and  `num_s2g` are described in the
[fourth version of the software](#user-content-fourth-attempt).

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
* `region_num` the `num` field of the regional path,
* `range1`,
* `coef1`,
* `coef2`.

Up  to  version  3,  `full_num`   and  `region_num`  are  the  numbers
identifying specific full paths  and specific regional paths. Starting
with version 4,  if the `specific_paths` flag from table  `Maps` is 0,
these columns refer to generic full paths and generic regional paths.

The use of fields `range1`, `coef1` et `coef2` is explained in
[fourth version of the software](#listing-all-specific-full-paths-linked-to-a-specific-regional-path).

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

French Maps
-----------

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

![4-way point in the South of France](point-quadruple.png)

Another  point, illustrated  by  the same  picture. Theorically,  each
border between departments  is specified twice in the  input file. For
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
`fr1970`+`1`  and `frreg`+`2`  by extracting  all departments  borders
`fr1970`+`2`  lying  between  two different  regions,  discarding  all
duplicates region-wise  and store the  result in the  `Borders` table.
And  it creates  in  the  same way  the  `Borders`  records with  keys
`fr2015`+`1`  and `frreg`+`1`  by extracting  all departments  borders
`fr2015`+`2` lying between two different regions.

Other Maps
----------

For the games I own, I take a 30-cm rule and I compile the list of X-Y
coordinates, respective  to the lower-left  angle. For the games  I do
not own, but which are described  on Internet, I load a graphical file
displaying the map,  I open it with  the Gimp, I point  to the various
areas with my mouse and for each one, I write the pixel coordinates in
a text file. To compute the real longitude, I choose two points on the
map, I search  the Internet to find the real  longitudes. For example,
for the  Britannia maps, I  choose the western-most point  in Cornwall
(near Penzance)  and the  eastern-most point  in Kent  (near Margate).
With both longitudes  and both X coordinates and I  write a conversion
function

```
my $lon-Cor = -5.68;  # Cornwall 5°40' W
my $x-Cor   = 13;
my $lon-Ken =  1.41;  # Kent  1°25' E
my $x-Ken   = 41;
my $a-lon   = ($lon-Cor - $lon-Ken) / ($x-Cor - $x-Ken);
my $b-lon   = $lon-Ken - $a-lon × $x-Ken;
sub conv-lon(Num $x --> Num) { return $a-lon × $x + $b-lon }
```

I do the same thing with Y  coordinates and latitudes. I can reuse the
same points if they have very  different latitudes, or I can use other
points.  For  example,  with  Britannia, I  reused  Cornwall  for  the
Southern-most  latitude and  I  chosed Orkneys  for the  Northern-most
latitude.

The result can be very approximate. For example, see the map of
[War on Terror](https://boardgamegeek.com/image/134814/war-terror).
I used  Cape Horn and North  Cape to generate the  latitude conversion
function. Despite of this choice, the four Antarctic areas end up with
latitudes between 53°S  and 61°S. Of course, the  original map already
has some  distortion. But suppose we  use a perfectly drawn  map using
the Mercator projection, the use of a function such as:

```
sub conv-lat(Num $y --> Num) { return $a-lat × $y + $b-lat }
```

will not reproduce the variation of latitudes as given by the Mercator
projection.

Special Cases
-------------

For the [naval operation map] (https://boardgamegeek.com/image/308459/operation-mercury-german-airborne-assault-crete-19)
of _Operation Mercury_ and for the
[map of _Raid on St. Nazaire_](https://boardgamegeek.com/geeklist/154538/wargaming-maps-context?itemid=2555472#2555472),
the mapedges are not oriented west →  east and north → south as usual.
For _Raid  on St. Nazaire_, I  keep the map orientation  with south on
the left  and north  on the  right, so  the map  will be  displayed in
"landscape" orientation on my  "landscape" computer screen. Longitudes
and latitudes will have no significance.

On the other hand, with _Operation Mercury_, I rotate the naval map so
it can be  merged with the map  giving the land areas  of Crete island
(set-up in the  usual way, north on  top and south at  the bottom). So
the conversion functions for the naval map look like:

```
sub conv-lon(Num $x, Num $y --> Num) { return $lon0 + $x-lon × $x + $y-lon × $y }
sub conv-lat(Num $x, Num $y --> Num) { return $lat0 + $x-lat × $x + $y-lat × $y }
```

Computing the  values of coefficients `$lon0`,  `$x-lon`, `$y-lon` and
similar for the latitudes is not much more mysterious than in the case
of properly oriented maps. You have  to choose three points instead of
two  and  solve   three  equations  with  three   unkowns,  first  for
longitudes, then for latitudes. It is not mysterious, but the formulas
are much more cumbersome.

In some cases, the concept of longitude and latitude is irrelevant. In
these  cases,  field `with_scale`  of  table  `Maps`  is set  to  zero
(False). This is  the case with the dodecahedron of  the Icosian game,
this is the case with some games such as
[_The Awful Green Things From Outer Space_](https://boardgamegeek.com/image/6788404/awful-green-things-outer-space)
in which the mapboard represents  a spacecraft roaming the outer space
and, say, about 100-m long (or maybe 50  m, or 200 m, I have no way to
get  a precise  value).  In  this case,  I  took  the X-Y  centimetric
coordinates as-is  to fill  the longitude  and latitude  fields. Well,
nearly  as-is. The  reason  is  that when  you  store floating  values
without a fractional part in SQLite,  when you read these values back,
SQLite gives you integer values,  incompatible with Raku's `Num` type.
Therefore, the  initialisation programme adds a  small fractional part
so that  when you  read the  values afterwards,  SQLite will  give you
floating  numbers compatible  with Raku's  `Num`. When  displaying the
graphs, the  kilometer-scale will not  be displayed. This  scale would
have  been irrelevant  for the  dodecahedron  and it  would have  been
misleading for the
[_Znutar_ spaceship](https://boardgamegeek.com/image/1153757/awful-green-things-outer-space)
of _The Awful Green Things From Outer Space_.

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

![Map of Normandy](Normandie.png)

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
that the path `'50 → 61 → 14 →  27 → 76'` is no longer a _partial_ path,
but a _complete_ regional path. It is stored in the `Paths` table and it
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
composed of one single node and no edge. In the picture below, you can
see that Y1970-regions  `BRE` and `IDF` are alone  in their respective
Y2015 regions, and  you guess the same applies  to Y1970-regions `PDL`
and `CEN`.

![Excerpt from the frreg map with Bretagne, Pays de la Loire, Centre-Val-de-Loire and Île-de-France](BRE-CEN-IDF-PDL.png)

Another case, exemplified by Wales in  the Britannia map, is not dealt
with at initialisation time. For  game reasons, Cornwall and Devon are
assigned to  Wales instead of  England. If  we do discard  the coastal
links, then Wales is not a connected  graph, it has a Cornwall + Devon
connected  component,  plus  a  main connected  component  (Powys  and
others).  This   case  is   not  dealt   with  during   the  programme
initialisation. The  programme will try to  generate Hamiltonian paths
nevertheless. Since  Cornwall and Devon  are dead ends,  the programme
will generate either `COR → DEV` or  `DEV → COR`, then it will fail to
extend this partial path. The  generation programme will soon end with
a  "failed" result,  as expected,  but it  will still  have run  for a
little while.

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

![HDF, NOR, PDL, NAQ and BRE areas](HDF-NOR-PDL-NAQ-et-BRE.png)

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

![HDF area](HDF.png)

This process may encounter blocked situations. This is the case if we continue
the example above with a `... → 62  →→ GES → ...` path. We can find no
departments which are simultaneously  neighbour of the `62` department
and belong to the  `GES` region. In this case, no  new partial path is
stored into the `to-do` list after  the previous partial path has been
removed.

The blocked situations can appear a bit later. The programme may find a small
area neighbouring the currently final  small area, but this small area
is the starting point of no  regional Hamiltonian path. Let us suppose
we have a  path such as `... →  78 →→ NOR → ...`.  The programme finds
just one neighbouring department `27`  (Eure), but in the `NOR` region
(Normandy), the  `27` node  is an articulation  point, so  no regional
Hamiltonian path ever  starts from `27`. The programme  will not store
any partial path into the `to-do` list after removing the `... → 78 →→
NOR → ...` path.

![From 78 to NOR](78-NOR.png)

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
IDF → GES ...`. The access from `HDF` (`60` or `80`) is either through
`77` (Seine-et-Marne)  or through  `95` (Val-d'Oise)  and the  exit to
`GES` (`10` or `51`) must be from `77`.

![Map of IDF region with HDF and GES neighbours](HDF-IDF-GES.png)

Without optimisation, there are 104  regional paths starting from `77`
and 93 regional paths from `95`.  The programme would push 197 partial
paths into the `to-do` list.

```
select max(P.from_code), max(A.exterior), count(*)
from Region_Paths P
join Small_Areas  A
  on A.map   = P.Map
  and A.code = P.to_code
where P.map  = 'fr2015'
and   P.area = 'IDF'
group by P.from_code, A.exterior
```

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

```
select max(P.from_code), max(P.to_code), count(*)
from Region_Paths P
where P.map  = 'fr2015'
and   P.area = 'IDF'
and   exists (select 'x'
              from Small_Borders B
              where  B.map       = P.Map
              and    B.from_code = P.to_code
              and    B.upper_to  = 'GES')
group by P.from_code, P.to_code
```

Another point: from  reasons similar to the  generation of Hamiltonian
macro-paths  and the  generation  of Hamiltonian  regional paths,  the
`to-do` list is processed in a LIFO  order, rather than FIFO. To get a
numeric  order consistent  between  the full  paths  and the  regional
paths, the partial paths are  pushed ordered by decreasing path number
and  popped by  increasing path  number. This  is the  reason why  the
regional paths  are selected  from the  database with  decreasing path
number. The  exception is the  last step, because the  generated paths
are no  longer partial paths  pushed into  the `to-do` list,  but full
paths stored into the database.

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
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
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
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
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
"be sure to link with the `*` virtual department" clause. There is no need to
insert a double  arrow, it has already been inserted  in step zero, we
need just  to slide it  like in  steps 2 to  11. The virtual  area `*`
appears  only  in the  `Borders_With_Star`  view,  that will  be  used
instead of the `Small_Borders` in all SQL statements above.

The  `Borders_With_Star` view  also allows  us  to merge  step 12  for
`fr2015` with the  single step for a one-region map.  During this last
step, we remove the `* →` prefix that was added in step 0.

Adding a new small area `*`  does not change the generated full paths.
Since no macro-paths include the `*` virtual region which contains the
`*` virtual  small area, there is no  risks that a full  path would be
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

The front page  is nothing more than the list  of all available maps.
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
http://localhost:3000/en/region-path/fr2015/HDF/1

* A regional map with a (truncated) full path. URL
http://localhost:3000/en/region-with-full-path/fr2015/HDF/3

### Parameters For The Picture Size

For each page, you can add parameters `h` and `w` to tweak the heights
and widths of the drawings. For example, if we want to display the map
in a 500 by 700 pixel rectangle:

  http://localhost:3000/fr/full-map/fr2015?w=500&h=700

This is the basic  idea. A first exception is a map  with a single big
area. To  avoid a huge blank  page when displaying the  macro-map, the
canvas size  is reduced to  the minimal  size that allows  drawing the
single area.  The programme does  not use  the values from  the string
`?h=700&w=500`.

Another case  is when you are  bothered by the fact  that the vertical
scale and the horizontal scale are much different. So there is a third
parameter to overload the `h` and `w` parameters. Possible values are:

* `adj=h`, the `w`  parameter for the horizontal scale  is ignored and
its value is updated to give the same pixel-per-kilometre scale as the
`h` parameter.

* `adj=w`, the `h` parameter for the vertical scale is ignored and its
value is updated to give the same pixel-per-kilometre scale as the `w`
parameter.

* `adj=max`, the programme compares the vertical and horizontal scales
(in pixels-per-kilometre) and keeps the higher.

* `adj=min`, the programme compares the vertical and horizontal scales
(in pixels-per-kilometre) and keeps the lower.

Of course, this is relevant only for maps of the surface of Earth with
a  cylindrical  projection,  in   other  words  maps  with  attributes
`with_scale=1`.  For abstract  maps,  the adjustment  is  done on  the
"pixels-per-pseudo-degree" values.

Let us use the example of Britanny and its neighbour departments.

![Bretagne](Bretagne.png)

The  latitudes range  from  47.36°N (Loire-Atlantique  44) to  49.15°N
(Manche 50),  which gives 1.79° or  200 km. The longitudes  range from
0.95°W (Maine-et-Loire 49)  to 4.01°W (Finistère 29),  which gives 257
km.

With  parameter  string  `?h=700&w=500`,  we get  3.5  pixels  per  km
vertically and 1.94 pixel per km horizontally.

With  string `?h=700&w=500&adj=h`,  the picture  height overloads  its
width, so we have  3.5 pixels per km in both  directions and the width
is extended to 900 pixels.

With  string `?h=700&w=500&adj=w`,  the  picture  width overloads  its
height, so we have  1.94 pixels per km and the  height is shortened to
388 pixels.

With parameter  string `?h=700&w=500&adj=min`, the  programme compares
both scales 3.5 pixels / km and  1.94 pixels / km and keeps the second
one, which gives in this case the same result as `?h=700&w=500&adj=w`.
On the  other hand,  the parameter string  `?h=700&w=500&adj=max` will
result in the programme choosing the bigger scale, 3.5 pixels / km and
will adjust the width to 900 pixels.

Other Possibilities
-------------------

A programme `export.raku`  allows you to export various  graphs to the
`.dot` format. Then, you can create graphical files with
[Graphviz}(https://graphviz.org/)
(`neato`) or use them interactively with
[`tulip`](https://tulip.labri.fr/site/).

The  export programme  allows you  to choose  the directory  where the
`.dot` files will be created.  Other command line parameters allow you
to choose  which graphs  are exported  for a given  map: the  full map
graph, the  macro-map graph or the  regional maps graphs (all  or only
those specified in the command line).

Nodes and edges are exported with their colours and their longitudes /
latitudes,  so   the  rendering  by   Graphviz  or  Tulip   should  be
approximately the same as the rendering by `website.raku`.

A Few Remarks
-------------

### Bailador or Cro?

In 2017, I worked on a
[Perl project](https://github.com/jforget/Perl-fixed-width-char-human-recognition)
using
[Dancer2](https://metacpan.org/dist/Dancer2/view/script/dancer2).
In 2018, when learning Raku (then named Perl 6), I worked on a
[Raku projet](https://github.com/jforget/Perl6-Alpha-As-des-As-Zero)
with the Raku port of Dancer / Dancer2,
[Bailador](https://raku.land/cpan:UFOBAT/Bailador).
So  I naturally  chose Bailador  when I  began working  on Hamiltonian
paths in 2022.

My main computer has the following configuration:

* system Devuan 2 ASCII until January 2023, Devuan 4 Chimera after that

* rakudo v2020.12

* Bailador:ver<0.0.19>:auth≤github:Bailador≥

Note:  because  of the  way  the  char  "less  than" is  processed  by
Markdown, I have changed some of them  with a char "less than or equal
to" and  for consistence, I  have changed the balancing  char "greater
than" with "greater than or equal to".

Since a date I  do not remember, possibly in 2024  but with no further
precision, program `website.raku` fails  at start-up with segmentation
errors. At first,  I did not care  much, because I just  had to repeat
the shell command a few times and `website.raku` would run fine.

On another  computer, program  `website.raku` would give  no problems.
The configuration of this secondary computer are:

* system xubuntu 22.04 Jammy Jellyfish

* rakudo v2022.02

* Bailador:ver<0.0.19>:auth≤github:Bailador≥

In April  2025, I wanted to  analyse the reasons for  the segmentation
errors by installing and running  `website.raku` on a virtual machine.
The configuration is:

* system Fedora 41

* rakudo v2024.12

* Bailador:ver<0.0.19>:auth≤github:Bailador≥

The installation of Bailador failed, because the distribution `Digest`
contains   no  module   `Digest.rakumod`  or   `Digest.pm6`,  required
(directly  or indirectly)  by `Bailador.pm`.  This is  written in  the
`README.md` file  of the Digest  distribution.

For what it is worth, the versions of `Digest` are:

* Devuan : Digest:ver<0.7.2>:auth≤Lucien Grondin≥

* xubuntu : Digest:ver<0.18.5>:auth≤Lucien Grondin≥

* Fedora : Digest:ver<1.1.0>:auth≤zef:grondilu≥

Using option `--force` does not improve anything. I could overcome the
problem  in several  ways.  I could  have  written a  `Digest.rakumod`
module to act as a proxy for `Digest::MD5` and `Digest::SHA1`. I could
search  the source  files for  Bailador and replace  all `use  Digest`
statements by `use  Digest::MD5` and `use Digest::SHA1`  (and create a
pull request). I could download and install an older version of Digest
from the
[Raku modules archive](https://github.com/Raku/REA/tree/main).

On the other hand, when browsing the documentation for Bailador, I found
[issue 315](https://github.com/Bailador/Bailador/issues/315)
which stated that, for now, Bailador is no longer actively developped.
Therefore, I decided to write a new program `website1.raku` using Cro.
Since the Bailador-based program  `website.raku` is still operative on
my xubuntu machine, and since my requirements for the website are very
basic,   I   will   endeavour    to   update   the   various   modules
`lib/xxx.rakumod` so  they will be  compatible with both  the Bailador
version and the Cro version. Yet, if I hit a roadblock, I will forsake
the Bailador version and keep only the Cro version.

In retrospect: the migration was a rather easy task. There were just a
few minor problems. For example, to display the list of maps, Bailador
accepts both adresses below:

```
http://localhost:3000/en/list
http://localhost:3000/en/list/
```

On the other side, Cro accepts the following address:

```
http://localhost:10000/en/list
```

but on the  other hand, the following address, with  a trailing slash,
is refused:

```
http://localhost:10000/en/list/
```

Paradoxically, another  problem comes from  a feature present  in Cro,
but   missing  from   Bailador.   The  display   parameters  such   as
`?h=600&w=800` are  parsed by Cro  and provided as a  hashtable, while
Bailador  just provides  the raw  string,  which requires  the use  of
another module  `PostCocoon::Url`. As  a consequence, the  Cro program
`website1.raku`  uses the  elements from  the hashtable,  rebuilds the
parameter string and calls the  modules generating responses with both
the  parameter  hashtable  and   the  parameter  string.  The  modules
generating reponses use the hashtable to control the generation of the
image and they use the string to generate URLs. On the other hand, the
Bailador program `website.raku`  calls the same modules  with only the
string, and  thanks to  the default  value declaration,  these modules
receive an empty hashtable, which signals them that they need to parse
the parameter string with `PostCocoon::Url`.

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
canvas  dimensions,  that  is,  1000 × 1000  pixels, later reduced to 800 × 800.  For  continental
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

### What about maps with only one big area?

Actually, I had a division-by-zero once. When I added the Icosian game
to the  list of test  data, when working  on version 5,  the macro-map
would display a single Big Area, so the min-to-max difference was zero
for  both longitudes  and  latitudes. Therefore,  I  added a  positive
number, yet a very small one, to the min-to-max differences.

Then I  added more maps  with a single  Big Area each,  including real
maps located on Earth. Still no problems. Then I added the map for
[Shoot-out at the Saloon](https://boardgamegeek.com/image/121547/bounty-hunter-shootout-at-the-saloon),
which represents  four streets enclosing  a single saloon.  This would
very roughly represent  a 40 m × 40 m square. Having  no indication of
the location where the game takes  place, I adopted the coordinates of
Tombstone, the famous town where the
[Gunfight at the O.K. Corral](https://en.wikipedia.org/wiki/Gunfight_at_the_O.K._Corral)
took place.

The macro-map would display as usual  for maps with a single Big Area.
But the  full map and  the regional map would  be awkward, with  a few
points in  the upper-left corner and  an empty strip on  the right and
another empty strip on the bottom. Why did this happen? When computing
the  min-max  difference,   I  used  an  initial   value  `1e-3`.  One
milli-degree represents a length of 111 m  in the NS direction and, at
Tombstone's latitude,  a length of  95 m in  the EW direction.  So the
picture would  display a  71 m empty  strip at the  bottom and  a 55 m
empty strip on the right.

So I changed this value to `1e-6`, which fixes the problem for
[Shootout at the Saloon](https://boardgamegeek.com/boardgame/3089/bounty-hunter-shootout-at-the-saloon)
without any  side effect for  the other  maps. The problem  will arise
again if  I find  a concrete  map which  fits inside  a 11 cm  × 11 cm
square. For the moment, no such example comes to my mind.

### Storing latitudes and longitudes in SQLite

In Raku  programmes, latitudes  and longitudes  are `Num`  values, not
`Int`. Yet, it may  happen that a latitude or a  longitude has a value
[with a fractional part equal to zero](https://confluence.org/).
It happens especially with abstract graphs such as the Icosian game or
the  Platonic solids.  In this  case,  even if  you use  a `Num`  when
storing the  longitude and  latitude into SQLite,  when you  read back
these values,  they are retrieved  as `Int`'s. And the  Raku programme
refuses to load these values into `Num` variables.

The workaround  is to always add  a very small value,  such as `1e-8`.
Thus,  the longitude  or latitude  is stored  into SQLite  as a  float
number  and when  it  is retrieved,  it  can be  stored  into a  `Num`
variable. Since  1 degree is 111  km (for latitude) or  less than that
(for  longitude),  the bias  is  about  1  millimeter on  the  ground,
therefore invisible on the map.

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

In the picture below, which are hard-copies from
[Géoportail](https://www.geoportail.gouv.fr/),
you can see the  south-east dent on the Moselle and  the south dent on
Cantal.  For comparison  purposes,  the picture  includes  the map  of
Mayenne, a  department with a  more regular  shape and which  may seem
nearly convex when seen from some distance.

![Maps of Mayenne, Moselle and Cantal](Mayenne-Moselle-Cantal.png)

With the method I used to  initialise the longitudes and latitudes for
the departements,  a department  could not be  represented by  a point
outside the  geographical limits of  the department. Even with  a very
deep dent, I would have chosen a point within the department. But if a
region  had a  dent similar  in proportions  to Cantal's  or Moselle's
dent, the average longitude and the average latitude could have placed
the centre  of the  region inside  the dent  and outside  the region's
borders. This is not the case  with the French regions (both the Y1970
ones and the Y2015 ones).

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

![Britannia: regional map for the sea areas and macro-map](Britannia-mer.webp)

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

### Crossing the International Date Line

#### First Version

Some maps show  the whole Earth and they include  links from a western
area  to an  eastern area,  across  the International  Date Line.  For
example, Alaska → Kamtchatka in
[Risk](https://boardgamegeek.com/image/79615/risk)
or Alaska  → Northern Russia in
[War on Terror](https://boardgamegeek.com/image/134814/war-terror).
In this  case, both nodes  should be  displayed twice: main  Alaska at
longitude 152 W and shadow Alaska  at longitude 208 E, main Kamtchatka
at longitude 130 E and shadow  Kamtchatka at longitude 230 W. The edge
would be drawn  twice, a first time from  152 W to 230 W  and a second
time from 208 E to 130 E.

I thought it  would be easy to  implement. It was not.  It was neither
easy,  nor  difficult,  but  kind  of average.  It  still  deserves  a
description, which you will find below. This description will be based
on an reduced Risk map, as shown below.

![Extracts from Risk showing the crossing of the International Date Line](cross-idl.webp)

The needs are different for full maps (and macro-maps) on one side and
for regional maps on the other side.

On full maps, both areas must appear twice:

* Main Alaska at longitude 152 W

* Shadow Alaska at longitude 208 E (208 = -152 + 360)

* Main Kamtchatka at longitude 130 E

* Shadow Kamtchatka at longitude 230 W (-230 = 130 - 360)

and the horizontal scale must use the full range 230 W → 208 E.

On a Northern America regional map, both areas appear only once:

* Main Alaska at longitude 152 W

* Shadow Kamtchatka at longitude 230 W

and the horizontal scale must use a range limited to 230 W (shadow Kamtchatka) → 32 W (Iceland).

On an Asia regional map, both areas appear only once:

* Shadow Alaska at longitude 208 E

* Main Kamtchatka at longitude 130 E

and the horizontal scale must use a range limited to 5 W (Europe) → 208 E (shadow Alaska).

Regional maps, full  maps and macro-maps are rendered  as PNG pictures
by the same  module, `map-gd.rakumod`. How can this  module tell apart
regional maps from  full maps and macro-maps?  The `@borders` variable
gives the answer. Inner borders appear  twice in the list, for example
`ALB → NWT` and `NWT → ALB`, while the outer borders appear only once.
Thus, when rendering the Northern  America regional map, you will have
`ALA → KAM` but  not `KAM → ALA` and when  rendering the Asia regional
map, you will have `KAM → ALA` but not `ALA → KAM`. When rendering the
full map, this border is an inner border (respective to the full map),
so the list will contain both `ALA → KAM` and `KAM → ALA`.

Let us see the questions separately.

In which circumstances is a shadow  area drawn?

A shadow area is drawn when it appears as the `to_code` of a cross-IDL
border.  This fact  is memorised  in variable  `%long-of-shadow-area`,
which is used both as a boolean  and a numeric (the longitude where it
will be  drawn). If both `ALA  → KAM` and  `KAM → ALA` appear  in list
`@borders`, that means we are drawing a full map and both "shadow ALA"
and "shadow KAM" will be displayed.  If only `ALA → KAM` appears, that
means that we are drawing the  region map of Northern America and that
"shadow KAM"  will be drawn,  but not "shadow  ALA". By the  way, that
`Bool+Num` convention means that no longitude can be strictly equal to
zero. So  if an  area needs a  zero longitude, it  will be  amended to
`1e-8` or the like.

In which circumstances is a main area drawn?

There are three  criteria. The most frequent criterion is  that a main
area is drawn if it appears in  a border with `cross_idl == 0`, either
as `from_code` or as `to_code`. Another  criterion is that it is drawn
if  it appears  in a  cross IDL  border as  its `from_code`.  With the
example above, if  the `ALA → KAM` border appears,  that means that we
are drawing either a full map, or a regional map for Northern America.
In both cases, "main ALA" must be drawn. A last case is if the area is
an isolated area  (big area `ICO` in map `ico`,  or island areas `HEB`
and `ORK` in Britannia's map when  using only the ground borders). You
will have to draw this isolated  area. This fact is stored in variable
`%must-display-main`: if the value is  `False`, the "main area" is not
displayed; if the value is `True` _or if it is missing_, the main area
is displayed.  This is why  I used the `//=  True` code. If  the value
does not exist, that means the area  does not appear in any border, so
this  is  an  isolated  node  (island), and  its  (missing)  entry  in
`%must-display-main`  is  upgraded  to  `True`. If  the  value  exists
already,  it is  not upgraded,  so `True`  remains `True`  and `False`
remains `False`.

How do we compute the longitude range for the horizontal scale?

As all borders  then all areas are examined, each  time we decide that
the  area  must  be  drawn,  we   store  its  longitude  into  a  list
`@longitudes`.  Of course,  if both  "shadow ALA"  and "main  ALA" are
displayed, we store both longitudes `-152` (main) and `+208` (shadow).
Then, when all borders have been examined and when all areas have been
examined, we extract the `min` and the `max` from this list and we get
the longitude range.

Remaining problems:

Two special  cases for borders will  not work well together:  a border
both crossing IDL and having a waypoint.  I have not tested and I fear
some silly behaviour.

We suppose  that no big  area straddles the  IDL. If the  case appears
(think Alaska before  1867, under the Russian rule), we  might have to
split the big area  in two parts. We can bet that  in this case, there
would be  only one cross-IDL  `Small_Border`. In this  case, splitting
the `Big_Area` will not change  the generated Hamiltonian paths. Since
there  is only  one such  border,  that means  that its  two ends  are
articulation  points (or  dead-ends),  which  channel the  Hamiltonian
paths.  A  real problem  would  occur  if  there  were _two_  or  more
cross-IDL borders, such as  both `KAM → ALA` and `JAP  → ALA`. In this
case, splitting big area "pre-1867 Russia" into two parts could change
the list of generated Hamiltonian paths.  But let's face it: this will
happen once in a blue moon.

Here is the macro-map for
[Twilight Struggle](https://boardgamegeek.com/boardgame/12333/twilight-struggle).
The longitude scale and the latitude scale are equal.

![Macro-map for Twilight Struggle](Twilight-Struggle-macro-v1.png)

As you can see,  the link from USA to big area  `ASI` (Asia) spans one
third  of the  picture.  And  since it  is  drawn  twice, it  occupies
actually two thirds of the picture. The explanation is this: longitude
of area `USA` is 84°W (near  Albany, in Georgia) and longitude of area
`ASI` is  103°E (between Thailand  and Cambodia). So the  shadow areas
are at 276°E  and 257°W respectively, which gives an  overall width of
533°. This overall width has twice 173° for the `USA → ASI` border and
only 187° for the inner part of the map. Therefore, a second version

#### Second Version

We discard the notion  of "shadow area" and we add  a new use-case for
the waypoint  in the border record.  If a border crosses  the IDL, the
initialisation  programme  feeds  the  `long` and  `lat`  fields  when
storing a  `Borders` record. The  latitude can  be computed, as  it is
done in the `init-risk-extract.raku` programme, or it can be extracted
from the init file,  like it is done for other reasons  with the `93 →
95` border  in the `fr1970` and  `fr2015` maps, or several  borders in
the `ratp` map.  The longitude is either 180°E or  180°W, according to
the border `from_code` area. For example,  in the `ASI → USA` border ,
the  longitude will  be +180  (or  180°E), while  in the  `USA →  ASI`
border,  the longitude  will be  -180 (or  180°W). With,  as explained
above, a fractional part.

Then, when the  drawing programme deals with this border,  it draws it
in  two segments,  one reaching  longitude 180°E,  the other  reaching
longitude 180°W.

The result is more balanced than the previous version:

![Macro-map for Twilight Struggle](Twilight-Struggle-macro-v2.png)

Only  the  initialisation programmes  and  the  drawing programme  are
affected. The programmes  which compute the Hamiltonian  paths and the
programme which computes the statistics for the shortest paths are not
modified.

#### Examples of Initialisation Programmes

The Git repository provides two initialisation programmes for the Risk
extract  map. In  the first  example, the  data file  is used  only to
declare that  such and such big  borders cross the IDL.  The programme
propagates the  `cross_idl` indicator to the  `Small_Borders` records.
Also, it computes the latitude where the borders cross the IDL (linear
variation with  respect to  the longitude)  and updates  all `Borders`
records with this latitude and the associated longitude.

In the  second example, all cross-IDL  borders are listed in  the data
file,  both  `Big_Borders`  records and  `Small_Borders`  records.  In
addition, these  borders must be declared  on two lines, one  line for
the East relay point, the other for the West relay point.

Using  longitudes 180°E  and 180°W  is not  mandatory. You  may use  a
shorter longitude range  which will generate a  more detailed drawing.
Let us use the example of
[Labyrinth: The War on Terror, 2001 -- ?](https://boardgamegeek.com/boardgame/62227/labyrinth-the-war-on-terror-2001).
In the West → East direction,
[the map](https://boardgamegeek.com/image/766726/labyrinth-the-war-on-terror-2001)
spans from Senegal (15°W) to Philippines (120°E). The locations
of Canada and United States are
[adjusted](https://tvtropes.org/pmwiki/pmwiki.php/Main/ArtisticLicenseGeography)
to fit within this range, which gives 9°W and 17°W respectively. There
is a  border from  the USA  to Philippines. Drawing  a relay  point at
180°W would be silly, with a  153° shift from the (relocated) USA. The
relay point is  drawn at 22°W, which  is enough. In the  same way, the
other relay point is drawn at 130°E instead of 180°E.

As for the second programme for the Risk extract, the relay points for
the `ALA → KAM` border are at 158°E and 170°W.

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
would produce 16 182 complete paths after processing 3 562 769 partial
paths. So there were more than 3 millions commits instead of just 162.

I removed the superfluous `commit`  + `begin transaction`. The leak is
not plugged, but it happens 162 times instead of 3 millions, so it has
no visible effects.

### SQL Syntax

When we  join several tables,  it is  advised to qualify  every column
name  with the  table name,  or to  give an  alias to  each table  and
qualify each column name with this alias.

First, the wrong example:

```
select num, path, area, to_code
from Borders_With_Star A
join Region_Paths B
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
where A.map       = ?
and   A.from_code = ?
and   A.upper_to  = ?
```

Then the right example:

```
select B.num, B.path, B.area, B.to_code
from Borders_With_Star A
join Region_Paths B
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
where A.map       = ?
and   A.from_code = ?
and   A.upper_to  = ?
```

Yet, this  SQL statement has  a problem. When I  ran it on  a computer
with the parameter `:array-of-hash`, the programme gave:

```
({B.num => 1, B.area => IDF, B.path => 'xxx → yyy', B.to_code => '77'})
```

and when I ran it on  another computer, with a different Raku version,
a  different  DBIish  version  and a  different  SQLite  version,  the
programme gave:

```
({num => 1, area => IDF, path => 'xxx → yyy', to_code => '77'})
```

How can  we avoid  this problem?  By giving an  attribute also  to the
columns:

```
select B.num     as num
     , B.path    as path
     , B.area    as area
     , B.to_code as to_code
from Borders_With_Star A
join Region_Paths B
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
where A.map       = ?
and   A.from_code = ?
and   A.upper_to  = ?
```
On both computers, I obtained:

```
({num => 1, area => IDF, path => 'xxx → yyy', to_code => '77'})
```

First Attempt
=============

Here are  the results  of the  paths generation,  while the  full path
generation is optimised with the `exterior` field of the `Small_Areas`
view.

`frreg`, regions from 1970 within regions from 2015
---------------------------------------------------

The first  map generated was  the easiest,  `frreg`: 12 big  areas, no
more than 3  small areas per big area. The  first generation programme
ran for  12 seconds, generating  864 macro-paths (with  26 476 partial
paths) and, for each region, from 2 to 6 regional paths.

The  second generation  programme  ran  a bit  longer,  5 minutes,  to
generate 210  full paths (with  9606 partial paths, while  the maximum
size of the to-do list was 7 partial paths).

`brit0`, Britannia map without the coastal links
------------------------------------------------

To check  a programme, you should  not test only the  sucessful cases,
but also the error cases. So I  decided to deal with the Britannia map
without  the  coastal  links,  that  is, the  Britannia  map  with  an
unconnected Scotland region and an unconnected Wales region.

With only three big areas, there  are only two macro-paths, which were
generated immediately. The generation  for Scotland and the generation
for Wales were  also immediate. On the other hand,  the generation for
England  (20 nodes,  40  edges)  needed 7  minutes  to generate  16182
regional paths  (with 3 562 796 partial  paths, of which only  43 were
simultaneously in RAM).

The 7 minutes are split into 4 minutes for the generation proper and 3
minutes for the renumbering of the generated paths.

With no Hamiltonian regional paths  for Scotland and Wales, the second
generation programme stopped immediately.

`brit1`, Britannia map with the coastal links
---------------------------------------------

In the  variant taking in account  the coastal links, but  not the sea
areas, the three big areas are  connected graphs and the generation of
regional paths  succeeds. Scotland  immediately gets 6  regional paths
(with 190 partial paths, 9 of which simultaneously in the to-do list).
Wales immediately gets  8 regional paths (with 24 partial  paths, 4 of
which are simultaneously  in the to-do list). For  England, the values
are  the same  as for  `brit0`. Why  so few  partial paths  for Wales?
Because  the articulation  point in  Powys  acts as  funnel, with  the
result that partial paths are much fewer than in Scotland.

The second generation programme will fail. A human can easily see that
there  are three  dead ends:  Hebrides  and Orkneys  in Scotland,  and
Cornwall in  Wales. For the programme,  it is a bit  more complicated.
When dealing with  the macro-path `SCO →  ENG → WAL`, the  end will be
soon, because all regional paths in Scotland have Hebrides and Orkneys
at both ends, which do not allow to extend the path into England. When
dealing with the  other macro-path, `WAL → ENG →  SCO`, the processing
will be much longer. Among the 8 regional paths, the programme chooses
the two paths in Wales which ends  in an exterior region, in this case
Clwyd. Then, the programme chooses all England regional paths starting
from  Cheshire  or March  (Clwyd's  two  neighbours) and  stopping  at
another exterior  area. Then all  partial paths are  rejected, because
the two border  areas in Scotland, Strathclyde and  Dunedin, are never
the starting  points of a  regional path. This  is the reason  why the
programme has run  for 9 seconds, has pushed 786  partial paths in the
to-do list, with a maximum of  393 paths simultaneously present in the
list.

The number 393 is 392 + 1, where 392 is the number of English regional
paths starting from  Cheshire or March and stopping  at another border
area, even if this area is bordering  Wales and not Scotland, and 1 is
the other macro-path where the `WAL` region has been replaced with the
single regional  path that  reaches an  exterior region.  By selecting
only areas bordering  Scotland, this number would has  been reduced to
96 (= 1 + 95).

```
select count(*)
from Region_Paths as P
join Small_Areas  as A
  on  A.map = P.map and A.code = P.to_code
where P.map = 'brit1'
and   P.from_code in ('CHE', 'MRC')
and   A.exterior = 1
```

```
select count(*)
from Region_Paths as P
where P.map = 'brit1'
and   P.from_code in ('CHE', 'MRC')
and   P.area = 'ENG'
and   exists (select 'X'
              from  Small_Borders as B
              where B.map       = P.map
                and B.from_code = P.to_code
                and B.upper_to  = 'SCO')
```

`brit2`, Britannia map with the sea areas
-----------------------------------------

For the first programme, adding  sea areas changes nearly nothing. The
bulk of the time is still spent while processing England.

For  the  second programme,  using  the  same  ideas  as used  in  the
preceding paragraph, a human can easily  find that full paths can only
be derived from  the `SCO → OCE  → ENG → WAL`  and `WAL → ENG  → OCE →
SCO` macro-paths. On the other side, the second programme cannot think
in the same way. It tries all macro-paths, including the two fruitless
macro-paths starting from England. Among  the 16 182 regional paths in
England, 13 132 stop at a border area (remember that all coastal areas
are  now  border  areas).  So,  on both  occasions,  when  the  second
programme processes the two sterile  macro-paths, it pushes all 13 132
paths upto the `to-do` list, all of which will fail to generate a full
path.

```
select count(*)
from Region_Paths as P
join Small_Areas  as A
  on  A.map = P.map and A.code = P.to_code
where P.map  = 'brit2'
and   P.area = 'ENG'
and   A.exterior = 1
```

With the alternate  optimisation, the number of paths  stacked in vain
to the `to-do` list would drop from 13 132 to 1463.

```
select count(*)
from Region_Paths as P
where P.map = 'brit2'
and   exists (select 'X'
              from  Small_Borders as B
              where B.map       = P.map
                and B.from_code = P.to_code
                and B.upper_to  = 'SCO')
```

On  the other  hand, when  I run  this query  in `sqlitebrowser`,  the
answer  is displayed  after several  seconds.  Maybe this  is not  the
proper solution.

`mah1`, Maharaja map without the foreign lands and the seas
-----------------------------------------------------------

In the Maharaja  map, there are four big areas.  Two very simple ones:
Ceylon (2  small areas and  1 interior  small border) and  Himalaya (4
small areas  and 3 interior  borders), and two much  more complicated:
Northern India (18  small areas and 34 interior  borders) and Southern
India (12 small areas and 24 interior borders).

```
select max(upper), count(*)
from Small_Areas
where map = 'mah1'
group by upper

select max(upper_to), count(*) / 2
from Small_Borders
where map = 'mah1'
and   upper_to = upper_from
group by upper_from
```

The generation  of macro-paths  and the  generation of  regional paths
within  Himalaya and  Ceylon is,  you guess  it, very  fast. Something
curious happens  with the two  other regions. Northern India  has 1578
regional paths, but after processing 4 293 386 partial paths. Southern
India  has  nearly twice  as  many  regional  paths, 3088,  but  after
processing only 43 592 partial paths,  hardly more than one hundredth.
The max size of the `to-do` list  was 37 for Northern India and 26 for
Southern India.

The second programme ran for 7  minutes or so, to generate 13 464 full
paths,  while  generating  41 642 partial  paths  (361  simultaneously
present in the `to-do` list).

`mah2`, Maharaja map with the foreign lands and the seas
--------------------------------------------------------

The `mah2` map adds two more big areas: `ASI` for the foreign lands in
Asia (6  areas, 6 inner  borders) and `MER` for  the seas (3  areas, 2
inner borders).  Nothing changes  much when running  the `gener1.raku`
programme. The number of macro-paths raises from 2 to 56.

But the `gener2.raku` programme has run  for a very long time, about a
12-hour night  instead of 7 minutes.  And actually, I have  killed the
job in the morning. It was nearly  finished, but I could not wait. Why
did it take so long?

The  reason is  the same  as  for map  `brit2`, but  with much  larger
values.  In `brit2`,  there  was a  macro-border  between England  and
Scotland (small areas `STR` and  `DUN`), but no Scottish regional path
would  ever  start  from  `STR`  or  `DUN`.  In  `mah2`,  there  is  a
macro-border between Ceylon (`CEY`) and the sea region (`MER`), but no
regional  Hamiltonian  path within  `MER`  starts  from `OCE`  (Indian
Ocean). Therefore, the six Hamiltonian macro-paths  `SUD → CEY → MER →
etc`  will  generate no  Hamiltonian  full  paths. Unfortunately,  the
programme cannot guess it without doing the full extraction.

So on  6 occasions, the programme  pushes 2382 partial paths  into the
`to-do` list, to no avail.

```
select count(*)
from Region_Paths as P
join Small_Areas  as A
  on  A.map = P.map and A.code = P.to_code
where P.map      = 'mah2'
and   P.area     = 'SUD'
and   A.exterior = 1
```

With  the more  precise  optimisation, the  number  of Southern  India
regional paths would  be narrowed to 346. When multiplied  by 6, it is
still a  big number, but at  least much smaller than  the previous big
number 6 × 2382 = 14 292.

```
select count(*)
from Region_Paths as P
where P.map = 'mah2'
and   P.area = 'SUD'
and   exists (select 'X'
              from  Small_Borders as B
              where B.map       = P.map
                and B.from_code = P.to_code
                and B.upper_to  = 'CEY')
```

But wait, there is  more! We also have macro-paths `NOR →  SUD → CEY →
MER →  ASI → HIM` and  `NOR → SUD  → CEY → MER  → HIM → ASI`.  In both
cases, we first push 1416 partial paths to the `to-do` list: expansion
of `NOR`  with partial paths  within Northern  India and ending  at an
exterior  small area.  Of these  1416  paths, 793  cannot extend  into
Southern India and 623 can. Each of these 623 partial paths can extend
with between 192  and 423 Southern India regional  paths, depending on
whether the  end of the  Northern India  regional path is  adjacent to
`AND` only, to  `MAH` only, to both  `AND` and `GON` or  to both `MAH`
and `KHA`.  If using  the lower  value 192,  we get  2 ×  623 ×  192 =
239 232 partial paths  which will be pushed at one  time or another to
the `to-do` list to no avail.

```
select P.from_code, count(*)
from Region_Paths as P
join Small_Areas  as A
  on  A.map = P.map and A.code = P.to_code
where P.map      = 'mah2'
and   P.area     = 'SUD'
and   P.from_code in ('MAH','KHA','GON','AND')
and   A.exterior = 1
group by P.from_code

   AND  192
   GON  231
   KHA  231
   MAH  192
```

I will  not discuss further,  similar computations could give  a rough
value of the number of sterile  partial paths generated for `HIM → NOR
→ SUD → CEY → MER → ASI` or `ASI → HIM → NOR → SUD → CEY → MER`.

Maps `fr1970` and `fr2015`
--------------------------

For these  maps, the running time  of `gener1.raku` is fine:  nearly 2
minutes  for  `fr2015` and  3  minutes  for  `fr1970`. The  number  of
regional paths  is rather  low. The  biggest region  is Île-de-France,
with 8 departments,  17 interior borders and  800 Hamiltonian regional
paths (with  4014 partial  paths). On the  macro level,  the programme
generates 3982  macro-paths for  `fr1970` and  894 for  `fr2015`, with
respectively 448 223 and 26 476 partial paths.

On the other hand, I did not try to run `gener2.raku` on these maps. I
guess that  the running time would  be similar to `mah2`.  Each region
has fewer regional paths than `mah2`,  but there are 12 or 21 regions,
so the combinatorial explosion may be  as huge as for `mah2`. I prefer
waiting  for  the second  optimisation  to  generate full  Hamiltonian
paths.

Discarded Maps
--------------

There are  some maps  I have  not tried,  because they  cannot produce
doubly Hamiltonian paths,  or even regional Hamiltonian  paths. Let us
consider Africa in the
[War on Terror](https://boardgamegeek.com/image/134814/war-terror).
map. This  continent has  6 areas,  2 of which  are dead  ends: "South
Africa" and  "Madagascar", both linked to  articulation point "Sudan".
If there were  an Hamiltonian path within Africa, it  would start from
South Africa and  stop at Madagascar or the other  way. In both cases,
the Sudan articulation point would be  both in the second place and in
the next-to-last place. Awkward, isn't it? Actually, I later added the
_War on Terror_ map to  the database, with a South-Africa-less variant
and a Madagascar-less variant. In  both cases, my programmes generated
doubly-Hamiltonian paths.

The situation is worse in
[History of the World](https://boardgamegeek.com/image/384589/history-world),
there are  many dead ends.  As shown in  this
[partial picture  of the map](https://boardgamegeek.com/image/799290/history-world),
the  big area  "Northern Europe"  (in pink)  includes four  dead ends:
"Ireland", "Western  Gaul" and  "Danubia" visible  in the  picture and
"Scandinavia"  a bit  outside  the picture.  And  about the  "Southern
Europe" big area, how  can you move from dead end  "Crete" to dead end
"Southern  Appenines", while  crossing the  "Northern Appenines"  only
once and yet visiting the Iberic peninsula?

About
[Twilight Struggle](https://boardgamegeek.com/boardgame/12333/twilight-struggle),
both  big areas  "Central America"  and "Asia"  have three  dead ends:
"Mexico",  "Dominican  Republic"  and  "Panama"  in  the  first  case,
"Afghanistan", "North Korea" and "Australia"  in the second case (yes,
this big area should have been named "Asia-Pacific").

And there is another problem in the "Africa" big area. A simplified
version of this area is:

```
                                area A
                              /        \
dead end 1 --- articulation 1            articulation 2 --- dead end 2
                              \        /
                                area B
```

with  no  edge  between area  A  and  area  B.  How can  you  find  an
Hamiltonian path in this graph?

Actually, these maps are not  completely discarded. Since I have added
webpages to display shortest paths and similar notions, there is still
some interest  including _History of the  World_, _Twilight Struggle_,
_War on Terror_ and other maps in the database.

Conclusion
----------

The optimisation based  on the `exterior` flag is  not sufficient. The
good point  of the `where exists  (select 'x' ...)` clause  is that it
reduces drastically the  number of intermediate results.  On the other
hand,  as I  have found  on `sqlitebrowser`,  the queries  with `where
exists  (select  'x' ...)`  are  not  optimised  for SQL.  So  running
iterations  that are  fewer and  longer, I  am not  sure it  may be  a
beneficial change.

Although I am not master of the  world in an
[Arthur Clarke novel](https://tvtropes.org/pmwiki/pmwiki.php/Literature/TheSpaceOdysseySeries?from=Literature.TwoThousandOneASpaceOdyssey),
I am not quite sure what to do next. But I will think of something.

Second Attempt
==============

Let  us use  the example  of  a macro-path  `HDF  → GES  → ...`.  When
replacing the  `HDF` region with a  regional path, I try  to find only
paths  that would  connect to  the  following region  `GES`, that  is,
regional  paths for  which  the  department `Region_Paths.to_code`  is
linked with region `GES`.

![Région HDF](HDF.png)

"Linked with  region `GES`"  can translate to  "there exists  a border
between  department `Region_Paths.to_code`  and region  `GES`. In  SQL
syntax:

```
where exists (select 'x'
              from   Small_Borders
              where  from_code = Region_Paths.to_code
              and    upper_to  = 'GES'
```

With the current example, this  clause selects only the regional paths
ending at department `02`.

A long time ago, I learned that in SQL, the `where not exists` clauses
are  very inefficient.  When running  the SQL  statements in  the text
above within  `sqlitebrowser`, I see  that the `where  exists` clauses
too  are not  very efficient.  A  join would  be better.  Yet, in  the
present case, the join:

```
join Small_Borders
  on  from_code = Region_Paths.to_code
```

is not the  solution, because it would give  duplicate results because
of the borders `(02, 08)` and `(02,51)`. So what can we do?

* Create an index on `Small_Borders`. Yet, according to
[the SQLite documentation](https://sqlite.org/lang_createindex.html),
indexes apply only to tables, not views.

* Create an index  on `Borders`. Maybe. I will have  to alter a little
the SQL statements,  to use this table instead  of the `Small_Borders`
view.

Then  I found  the solution.  Create  a table  or a  view with  either
`select distinct` or  `group by`, to merge the two  borders `(02, 08)`
and `(02,  51)` into  a single one  `(02, GES)`. To  be sure,  I first
write a benchmark.

Benchmark
---------

The benchmark receives three parameters:

1. The map. In the example above, this would be `--map=fr2015`.

2. The current region. In the example above, this would be `--current=HDF`.

3. The next region. In the example above, this would be `--next=GES`.

The programme runs six tests:

1. unindexed `where exists`, referred to as the "reference test",

2. indexed `where exists`,

3. table filled by `select distinct`,

4. view defined as `select distinct`,

5. table filled by `select ... group by`,

6. view defined as `select ... group by`.

Each test contains the following steps:

1. Copy the database file from the first attempt into a new database file.

2. Alter the new database file: create a new index, a new table or a new view.

3. In the case of tables, feed the new table.

4. Run the SQL statement extracting the regional paths which would be substituted to the region code.

Step 2 to 4 will be timed by extracting `DateTime.now` before and after the statement.

Lest some caching would introduce a bias in the benchmark, each one of
the 6 tests will  use its own database file. In  addition, the 6 tests
are run in a random order.

Lessons learned: as  I was suspecting, index creation  applies only to
tables. On the other hand, index  creation benefits views. I can still
code  a SQL  statement with  the  view instead  of the  table and  the
statement will run fast enough.

I was right when  I decided to run the tests in  random order. Even if
the tests use different files, we  can notice that the test which runs
first is  significantly slower  that the other  tests minus the
reference test. By  running several times the series of  tests, we can
see that  all five tests are  better than the reference  test and that
they are equivalent to each other.

Within the five solutions, I discard  the two solutions based on a new
table. There is a very slight  overhead during step 3 (a few thousandths of a second), because we have
to  fill the  table. Also,  this  table contains  only redundant  data
already  present  in  table  `Borders`,  therefore  it  degrades  the
database  normalisation. We  must  admit that  these  two reasons  are
rather feeble  reasons, but since  it is easy to  fix them, let  us do
that.

As for  the three other solutions,  I have no further  criterion, so I
adopt the view defined by `select distinct`. And with the
[fifth version of the software](#user-content-fifth-version),
I upgrade  this view to a  real table, because  I need to store  a new
column.

Result for the first programme
------------------------------

The `gener1.raku` programme  has not changed. So its  result should be
the same  as during  the first  attempt. Actually,  there is  a slight
variation in the  number of partial paths pushed to  the `to-do` list.
On  the other  hand,  the number  of complete  paths  stored into  the
database are the same, so I suppose the detailed contents is the same.

The difference  in the number of  partial paths is probably  caused by
the fact  that the `select` statements  have no `order by`  clause, so
the data are extracted in an undefined order, which can change between
a run  and the next. Also,  the programme uses a  `Set` data structure
and accessing  the elements of a  `Set` does not specify  the order in
which the elements are accessed.

Result for the second programme
-------------------------------

For the `gener2.raku` programme, the running time is divided by 3 to 4
between  the first  attempt  and the  second one.  For  the number  of
partial paths,  the ratio varies from  1.25 (`frreg`, 9606 →  7656) to
nearly 5 (`brit2`, 140278 → 27863).

For map `mah2`, since I have  killed the first attempt after 12 hours,
I base my computation on the  last message dealing with macro-path 50.
The  running time  to reach  this  point was  11h 45min  in the  first
attempt, and 4h 15min in the second  attempt, that is, a ratio of only
2.7. For partial paths, the ratio is a bit less than 2.

During the first attempt, I killed  the generation for `mah2` after 12
hours,  thinking that  all  full  paths were  generated  and that  the
programme was  nearly over.  Yet, as  the second  attemp shows,  I was
right that  all full paths were  generated, but on the  other hand the
programme  was  far from  over,  there  were still  several  fruitless
macro-paths to process. With a  proportional computation, we can guess
that the total runnning time would be a few minutes short of 17 hours.

![Régions PAC et LRO](PAC-LRO.png)

I have run the generation of full paths for map `fr1970`. I found that
there is still room for  optimisation, by discarding macro-paths which
cannot generate full paths. When  casually looking at map `fr1970`, we
notice  there  is  one dead-end  region,  `NPC`  (Nord-Pas-de-Calais),
linked  to only  `PIC` (Picardie).  On  the other  hand, region  `PAC`
(Provence-Alpes-Côte-d'Azur)  is linked  to two  other regions,  `RAL`
(Rhône-Alpes) and `LRO`  (Languedoc-Roussillon). Looking more closely,
we notice that the border  between `PAC` and `LRO` involves department
`30`  (Gard).  This department  is  an  articulation point  in  `LRO`,
therefore, no regional path can start  from `30` nor stop at `30`. The
next  consequence is  that no  full  Hamiltonian path  will cross  the
border between `PAC` and `LRO`. Region `PAC` then appears to be a dead
end region  functionally linked  to only  `RAL`. The  only macro-paths
able to generate full Hamiltonian paths are macro-paths beginning with
`NPC → PIC`  and ending with `RAL  → PAC` or the other  way. There are
only 486 fruitful macro-paths out of 3982.

This  case  is  found in  other  maps,  but  with  a lower  impact  on
processing times. In  map `brit2`, `SCO` (Scotland) is  linked to both
`ENG` (England)  and `OCE`  (Oceanic areas),  but no  full Hamiltonian
paths  crosses the  `SCO` to  `ENG` border  and `SCO`  is therefore  a
functional dead-end linked to only  `OCE`. Likewise, in `mah2`, region
`CEY`  (Ceylon) is  linked to  `SUD` (Southern  India) and  `MER` (sea
areas), but  only the border between  `CEY` and `SUD` is  used by full
Hamiltonian paths, `CEY` is functionaly a dead-end.

I have also run the generation of full paths for `fr2015`. I killed it
when I realised the number of  generated full paths would be huge. The
generation  ran  for  more  than  11  hours  and  processed  only  two
macro-paths, the second only only partially. The first one produced no
full paths, yet it took  one-and-a-half hour to reach this conclusion.
The second one was nearly at 2 millions when I killed the process. And
there are 894  macro-paths in all. Even if we  discard the macro-paths
which will  generate no  full paths, as  suggested above,  the running
time would still be huge.

Third Attempt
=============

The third attempt  aims to reduce the number of  macro-paths that will
be  processed  in  `gener2.raku`.  This  will  deal  with  "functional
dead-ends" as `PAC` in `fr1970` or `CEY` in `mah2`, but also the cases
without dead-ends  as the `IDF →  NOR` border in map  `fr2015`. I will
take this last example to illustrate the new case.

In table `Paths` and view `Macro_Paths` we have two new columns:

* `fruitless`, a numeric  flag. 1 if the macro-path  contains a border
such as `IDF → NOR` which  prevents the generation of full Hamiltonian
paths, 0 else.

* `fruitless_reason`, a string storing  the border which triggered the
problem.  If  a macro-path  is  deemed  fruitless because  of  several
borders, all borders are stored in  this string, separated by a comma.
This column is useless in the search algorithms, but it will give fine
results in the web pages and in the log files.

The column  `fruitless` is also added  to the `Borders` table  and the
`Big_Borders`  view. It  is also  added to  the `Small_Borders`  view,
since the borders  between small areas inherit  the `fruitless` values
from the borders between the corresponding big areas.

Feeding the New Columns
-----------------------

By default,  column `fruitless` is  initialised with 0.  The programme
loops  over  the  `Big_Borders`  view  (max  86  iterations,  for  map
`fr1970`).  For  each processed  border,  the  programme extracts  all
"Small  Borders" corresponding  to this  macro-border. Then  it checks
whether a full  path can cross these borders. In  case of failure, the
macro-paths containing the macro-border are updated.

![From 78 to NOR](78-NOR.png)

Example, processing the `IDF → NOR`  border in map `fr2015`. The small
borders are `78  → 27` and `95  → 27`. The programme  attempts to link
regional Hamiltonian paths from region `IDF` with either the `78 → 27`
border or  the `95 → 27`  border. Links exists, so  the programme does
not  update  the macro-paths.  Then  the  programme attempts  to  link
regional Hamiltonian paths from region `NOR` with either the `78 → 27`
border or the `95  → 27` border. No links are  found, so the programme
updates all macro-paths containing `'%IDF → NOR%'`.

Variant,  with  only one  `select`  but  two `update`.  The  programme
attempts to  link regional  Hamiltonian paths  from region  `NOR` with
either the  `78 → 27`  border or  the `95 →  27` border. No  links are
found, so  the programme updates  all macro-paths containing  `'%IDF →
NOR%'` as well as all macro-paths containing `'%NOR → IDF%'`.

Actually,  there  will be  four  `update`  statements. Any  macro-path
containing `'%IDF  → NOR%'` and  already flagged as fruitless  will be
updated by  contatenating `',  IDF →  NOR'` to  the existing  value of
`fruitless_reason`.  Any macro-path  containing  `'%IDF  → NOR%'`  and
still  flagged   as  not   fruitless  will   be  updated   by  filling
`fruitless_reason` with  `'IDF →  NOR'` and  `fruitless` with  1. Same
thing with `NOR → IDF`.

And there is a fifth `update`  statement. Once all borders between big
areas are processed, the  generation programme extends the `fruitless`
values to the borders between small areas.

Filling the `fruitless`  column requires that all  macro-paths and all
regional paths are generated. Since the `gener1.raku` programme allows
the  progressive  generation of  paths,  step  by step,  region  after
region,  the `fruitless`  column will  be filled  at the  beginning of
`gener2.raku`, when all necessary paths are generated.

Full Path Generation
--------------------

When generating  the full paths,  of course all  fruitless macro-paths
are discarded. We will no gain much by discarding macro-paths starting
with  `IDF  →  NOR  →  ...`  but there  will  be  huge  benefits  with
macro-paths ending with `... → IDF  → NOR`. Likewise, with map `mah2`,
the processing  will be  much faster  than the 7  hours of  the second
attempt.

On the  other hand, this new  optimisation will do nothing  to fix the
huge number  of full Hamiltonian  paths generated when  processing map
`fr2015`. For  map `fr1970`, instead  of spending 24 hours  to process
1461 fruitless  macro-paths and generating  0 full paths  before being
killed,  the  programme will  spend  _nn_  hours  to process  the  486
fruitful macro-paths between dead-end  `HPC` and pseudo-dead-end `PAC`
and generate millions of full paths.

This optimisation does  not mean that the  second attempt optimisation
is obsolete.  Both optimisations  are useful  and they  are compatible
with each other. The `Exit_Borders` optimisation reduces the number of
regional  paths processed,  the `fruitless`  optimisation reduces  the
number of macro-paths processed.

Result of the third attempt
---------------------------

As seen with the second attempt, there  are a few minor changes in the
first step, nothing of any significance.

For  maps  `frreg`   and  `mah1`,  no  macro-paths   were  flagged  as
`fruitless`, so the  running time was similar between  the second step
of the  second attempt and the  second step of the  third attempt: 1.5
min for `frreg` and 4 min for `mah1`.

For `brit1`, there are only two macro-paths, both of which are flagged
as  `fruitless`. The  second  step is  quasi  instantaneous. This  was
already the case for the second step of the second attempt.

I also ran the second step for map `brit0`, to check what happens when
a  macro-path is  flagged as  `fruitless` because  of two  `fruitless`
macro-borders instead of just one `fruitless` macro-border.

Map `brit2` has  12 macro-paths, only 2 of which  generate full paths.
For  the other  10  macro-paths,  8 are  flagged  `fruitless`. So  the
generation programme runs in vain for 2 macro-paths instead of 10. The
total processing time is reduced from 7 minutes to 2 minutes.

The  same happens  on a  bigger scale  with map  `mah2`. There  are 56
macro-paths,  40  of  which  do   not  generate  any  full  paths.  32
macro-paths are flagged as  `fruitless`. The generation programme runs
in vain for 8 macro-paths and generates full paths for 16 macro-paths.
The  total processing  time  is reduced  from  7 hours  to  1 hour  40
minutes. A big win and a welcome one.

For map `fr1970`, there is also  a big win. The first 3200 macro-paths
are kind-of processed  in a mere second, while this  would have lasted
more  than 24  hours in  the previous  attempt. Then,  in the  next 20
minutes or  so, the programme  processes macro-paths numbered  3201 to
3293 (35 with `fruitless` equal to  0 and 58 with `fruitless` equal
to 1)  without any full  path generated. Then the  programme processes
macro-path 3294  and generates more  than 177000 full  paths in 2  h 9
min, before I kill the process.

On the  other hand,  there is  a bit slowdown  with map  `fr2015`. The
first macro-path, which  has `fruitless` equal to  zero, but generates
no  full path,  has  been processed  in  4 hours,  while  it has  been
processed in 1 h 30 min in the previous attempt. The second macro-path
has generated  1 037 600 full paths in  about 4 hours before  I killed
the process.  In the previous attempt,  the same number of  full paths
has been generated in 3 h 22 min only.

Fourth Attempt
==============

The fourth attempt aims at reducing the combinatory explosion, where a
single macro-path in maps `fr1970` and `fr2015` can generate more than
1 million full paths.

![Areas IDF and CEN](IDF-CEN.png)

To explain the method, I will use map `fr1970`, while disregarding the
case of  dead-end `NPC` and  the case  of quasi-dead-end `PAC`,  and I
will  pretend to  use  a  FIFO approach  instead  of  the LIFO  method
currently implemented in `gener2.raku`. Let  us suppose we deal with a
macro-path starting with `* →→ HNO →  IDF → CEN → PDL`. The `HNO` area
is very simple, so the first generated partial path is `* → 76 → 27 →→
IDF → CEN`. Then, the programme feeds the `to-do` list with:

* 19 partial paths `* → 76 → 27 → 78 → xxx → 91 →→ CEN → PDL`
* 19 partial paths `* → 76 → 27 → 95 → xxx → 78 →→ CEN → PDL`
* 10 partial paths `* → 76 → 27 → 95 → xxx → 91 →→ CEN → PDL`

For each one of the 19 partial  paths from `78` to `91`, the programme
feeds the `to-do` list with:

* 1 partial path `* → 76 → 27 → 78 → xxx → 91 → 28 → yyy → 41 →→ PDL`
* 4 partial paths `* → 76 → 27 → 78 → xxx → 91 → 28 → yyy → 37 →→ PDL`
* 1 partial path `* → 76 → 27 → 78 → xxx → 91 → 45 → yyy → 28 →→ PDL`
* 1 partial path `* → 76 → 27 → 78 → xxx → 91 → 45 → yyy → 37 →→ PDL`

For each one of the 19 partial  paths from `95` to `78`, the programme
feeds the `to-do` list with:

* 1 partial path `* → 76 → 27 → 95 → xxx → 78 → 28 → yyy → 41 →→ PDL`
* 4 partial paths `* → 76 → 27 → 95 → xxx → 78 → 28 → yyy → 37 →→ PDL`

For each one of the 10 partial  paths from `95` to `91`, the programme
feeds the `to-do` list with:

* 1 partial path `* → 76 → 27 → 95 → xxx → 91 → 28 → yyy → 41 →→ PDL`
* 4 partial paths `* → 76 → 27 → 95 → xxx → 91 → 28 → yyy → 37 →→ PDL`
* 1 partial path `* → 76 → 27 → 95 → xxx → 91 → 45 → yyy → 28 →→ PDL`
* 1 partial path `* → 76 → 27 → 95 → xxx → 91 → 45 → yyy → 37 →→ PDL`

```
select max(area), from_code, to_code, count(*)
from Region_Paths
where map = 'fr1970'
and   from_code in ('78','95','28','45')
and   to_code   in ('78','91','28','41','37')
group by  from_code, to_code
```

This is  how the combinatory explosion  occurs. As you can  see, if we
could regroup together  all 19 regional paths  `78 → xxx →  91` into a
single  generic regional  path, if  we could  regroup all  19 regional
paths `95 → xxx → 78` into  another generic regional path, if we could
regroup all 10  regional paths `95 →  xxx → 91` into  a third regional
path and if we could regroup all 4 regional paths `28 → yyy → 37` into
a fourth regional path, the combinatory increase would no longer be an
explosive one.

So I  introduce a  new category  of paths,  generic regional  paths. A
generic regional path is the gathering  of all specific paths within a
region, sharing the same begin area and the same end area.

Likewise, there  are now  generic full  paths, built  by concatenating
generic   regional  paths,   plus  specific   full  paths,   built  by
concatenating  specific regional  paths.  The generic  full paths  are
stored in the database with `level=2`. The specific full paths are not
stored in the  database (there are millions of them  just for `fr1970`
and `fr2015`!), they are  built on demand when a web  page is about to
display this specific full path.

Yet, if the number of specific full paths is low enough (see parameter
`full-path-threshold`),   an   additional  programme,   `gener3.raku`,
rebuilds all these  specific paths and stores them  into table `Paths`
instead  of the  generic paths.  This  operation is  flagged in  table
`Maps` by updating the boolean field `specific_paths` to 1.

Relations Between The Various Paths
-----------------------------------

This  paragraph describes  the paths  relations in  maps flagged  with
`specific_paths = 0`.

Since  the  regional   paths  are  created  and   then  renumbered  in
`gener1.raku`, all specific  regional paths linked to  a given generic
regional path have contiguous numbers. For exemple, in region `IDF` in
map `fr1970`, the 19 regional paths from `78` to `91` are numbered 327
to 345.

In the records for the specific regional paths, we have:

* `num` = 327 to 345
* `level` = 2
* `generic_num` = 17.

In the record for the generic regional path, we have:

* `num` = 17,
* `level` = 4
* `first_num` = 327,
* `paths_nb` = 19.

Now, the `Path_Relations`  table holds the relation  between a generic
full path and a generic regional path.

`Paths`  table  and  `Full_Paths`  view:  the  field  `path`  contains
formulas which describe  the range of specific regional  paths in this
generic  full path.  Using the  example above,  the generic  full path
including all 19  regional paths from `78` to `91`  and all 4 regional
paths from `28` to `37`, the field `path` contains:

```
(HNO,2,1) → (IDF,327,19) → (CEN,7,4)
```

Another possibility, since  the generic path for `HNO` is  linked to a
single specific  regional path, maybe  the formula can  be immediately
replaced by the specific path:

```
76 → 27 → (IDF,327,19) → (CEN,7,4)
```

Rebuilding a specific full path
-------------------------------

This  paragraph describes  the paths  relations in  maps flagged  with
`specific_paths =  0`, both `website.raku`  which displays a  map with
`specific_paths  = 0`  and  `gener3.raku` which  converts  a map  with
`specific_paths = 0` to `specific_paths = 1`.

When `specific_paths = 0`,
specific full  paths are  not stored  in the  database. They  are just
known with  their keys:  map code  and sequential  number. How  can we
rebuild the full path when these two values are given?

Let us suppose we want path  number `2345` in map `fr1970`. First, the
programme extracts the corresponding generic full path:

```
select ...
where map = 'fr1970'
and   first_num <= 2345
and   first_num + path_nb > 2345
```

We get:

```
num         45
first_num   1800
path_nb     760
path        (HNO,2,1) → (IDF,327,19) → (CEN,7,4) → (PDL,8,2) → (PCH,20,5)
```

The programme extracts  the numbers of specific  regional paths, which
form  a list  `(1, 19,  4,  2, 5)`.  Then the  programme computes  the
numbers `x`, `y`, `z`, `t` and `u` from the equations:

```
2345 - 1800 = (((x × 19 + y) × 4 + z) × 2 + t) × 5 + u
0 ≤ x <  1
0 ≤ y < 19
0 ≤ z <  4
0 ≤ t <  2
0 ≤ u <  5
```

The results are:

* x =  0
* y = 13
* z =  2
* t =  1
* u =  0

The specific regional path numbers are:

* HNO:   2 +  0 =   2
* IDF: 327 + 13 = 340
* CEN:   7 +  2 =   9
* PDL:   8 +  1 =   9
* PCH:  20 +  0 =  20

The programme  reads these specific  regional paths. For each  one, it
loads the  field `path`,  and replaces  the formula  `(XX,YY,ZZ)` with
this  regional   path  within   the  generic   full  path.   When  all
substitutions are done, the specific full path is done.

Values 2, 237, 7,  8 and 20 can also be found  in field `first_num` of
the  records accessible  from  view `Generic_Region_Paths`.  Likewise,
values 1, 19,  4, 2 and 5  are stored in field `paths_nb`  of the same
records.

Listing All Specific Full Paths Linked to a Specific Regional Path
------------------------------------------------------------------

This  paragraph   describes  the  processing  of   maps  flagged  with
`specific_paths = 0`.

Remark: there is a bug in  the implementation of the feature described
below. If you do not intend to debug my code, you can skip
[to the conclusion](#user-content-conclusions-for-the-fourth-variant).
If you really  want to debug _my_  code, I will not mind.  I will even
thank you for your patches or your pull requests.

The specific  regional paths are stored  in the database, but  not the
specific full  paths, which are  generated only when required.  As for
table `Path_Relations`, it stores  the relation between generic paths,
not specific  paths. How  can we  generate the  list of  specific full
paths linked to a specific regional path?

Let us reuse the example above, trying to find all specific full paths
linked  to   regional  path   `(CEN,9)`.  Record  `(CEN,9)`   of  view
`Region_Paths`  gives the  key  of the  generic  regional path  (field
`generic_num`) and  the specific  path is the  third for  this generic
path (field `num_s2g` equal to 2, with a zero-based number scheme).

With the formula above, we find that the list of specific full paths is
given with this formula:

```
num =  1800 + (((x × 19 + y) × 4 + z) × 2 + t) × 5 + u
0 ≤ x <  1
0 ≤ y < 19
z = num_s2g = 2
0 ≤ t <  2
0 ≤ u <  5
```

The formula can be shortened in this way:

```
num =  1800 + coef1 × x + coef2 × y + z
0 ≤ x < range1 = 19,    coef1 = 4 × 2 × 5 = 40
    y = num_s2g = 2     coef2 =     2 × 5 = 10
0 ≤ z < range3 = 10    (coef3 = 1)
```

The way the  ranges and coefficients are defined, `coef3`  is always 1
and  `coef2` and  `range3` are  equal. So  the `Path_Relations`  table
stores the fields `range1`, `coef1` and `coef2`.

For generic path `(HNO,2,1) → (IDF,327,19) → (CEN,7,4) → (PDL,8,2) → (PCH,20,5)`,
the relations with the regional paths contain the following values:

| region | range1       | coef1    | (range2) | coef2    | (range3)     | (coef3) |
|:------:|:------------:|---------:|:--------:|---------:|:------------:|:-------:|
| HNO    | (empty)      | (empty)  | 0..^1    | 19×4×2×5 | 0..^19×4×2×5 |    1    |
| IDF    | 0..^1        | 19×4×2×5 | 0..^19   |    4×2×5 | 0..^4×2×5    |    1    |
| CEN    | 0..^1×19     |    4×2×5 | 0..^4    |      2×5 | 0..^2×5      |    1    |
| PDL    | 0..^1×19×4   |      2×5 | 0..^2    |        5 | 0..^5        |    1    |
| PCH    | 0..^1×19×4×2 |        5 | 0..^5    |        1 | (empty)      | (empty) |

The values "`(empty)`" correspond to logically unused values. To avoid
special  cases in  the formulas,  these  values will  contain a  range
`0..^1`, that is, containing a single zero, and a coefficient equal to 1.
Fields `range2`,  `range3` and  `coef3`  are not  stored in  table
`Path_Relations`, because  they can be  easily found elsewhere  in the
database or recomputed.

In the web  page "Full Path _nn_ Within Region  _XXX_", you would have
to run  this computation  for _all_  generic full  path linked  to the
displayed specific  regional path. In  the example above,  the generic
full path has 760 specific  full paths containing the "`CEN`" specific
regional  path. When  iterating over  all possible  generic full  path
containing the generic  regional path "`(CEN,7,4)`", you  may obtain a
huge list of paths.

We split the list in two parts. The first part include the list of all
specific full paths linked to the current generic full path and to the
current specific regional path (through the generic regional path).
The second part iterates over the generic full paths containing
"`(CEN,7,4)`" and each time selects a single specific full path as a
sample.

In summary, we want to display

```
https://localhost:3000/fr/egion-with-full-path/fr1970/CEN/2345
```

The generic full path (stored in the database) is `(fr1970,45)`, with:

```
num         45
first_num   1800
path_nb     760
path        (HNO,2,1) → (IDF,327,19) → (CEN,7,4) → (PDL,8,2) → (PCH,20,5)
```

The `num_s2g` numbers for the specific regional paths are:

| région | num_s2g |
|:------:|--------:|
| HNO    |  0      |
| IDF    | 13      |
| CEN    |  2      |
| PDL    |  1      |
| PCH    |  0      |

As we are interested in `CEN`, we put aside "`2`".

### First Part of the List

The first part of the list of specific full paths contains `760 / 4 = 190`
paths. This is a big list, so we build this list of shifts:

```
-200 -100 -90 -80 -70 -60 -50 -40 -30 -20 -10 -9 -8 -7 -6 -5 -4 -3 -2 -1 1 2 3 4 5 6 7 8 9 10 20 30 40 50 60 70 80 90 100 200
```

Since the `num_s2g` value for the current specific regional path is:

```
2345 - 1800 = 545 = (((x × 19 +  y) × 4 + z) × 2 + t) × 5 + u
2345 - 1800 = 545 = (((0 × 19 + 13) × 4 + 2) × 2 + 1) × 5 + 0
```

We remove the terms corresponding to `CEN`, which gives:

```
base = ((0 × 19 + 13) × 2 + 1) × 5 + 0 = 135
```

We add this base to the list of shifts, which gives:

```
-65 35 45 55 65 75 85 95 105 115 125 126 127 128 129 130 131 132 133 134 136 137 138 139 140 141 142 143 144 145 155 165 175 185 195 205 215 225 235 335
```

We restrict the  list to the `0..^190` window (the  number of specific
full paths in this part of the list), which gives:

```
35 45 55 65 75 85 95 105 115 125 126 127 128 129 130 131 132 133 134 136 137 138 139 140 141 142 143 144 145 155 165 175 185
```

For each resulting number, we recompute the split into `(x,y,t,u)` (no `z`):

```
n = ((x × 19 +  y) × 2 + t) × 5 + u
```

But is it faster with the `coef2` formula:

```
n = coef2 × x + y
```

Which gives:

```
35 = 10 × 3 + 5
45 = 10 × 4 + 5
55 = 10 × 5 + 5
...
134 = 10 × 13 + 4
136 = 10 × 13 + 6
...
185 = 10 × 18 + 5
```

We insert  back the "`2`" element  in these `(x,y)` doublets,  then we
apply the full formula "`coef1 × x + coef2 × y + z`":

```
 35 = 10 ×  3 + 5 → (3,5) → (3,2,5) → 40 × 3 + 10 × 2 + 5 = 145
 45 = 10 ×  4 + 5 → (4,5) → (4,2,5) → 40 × 4 + 10 × 2 + 5 = 185
 55 = 10 ×  5 + 5 → (5,5) → (5,2,5) → 40 × 5 + 10 × 2 + 5 = 225
...
134 = 10 × 13 + 4 → (13,4) → (13,2,4) → 40 × 13 + 10 × 2 + 4 = 544
136 = 10 × 13 + 6 → (13,6) → (13,2,6) → 40 × 13 + 10 × 2 + 6 = 546
...
185 = 10 × 18 + 5 → (18,5) → (18,2,5) → 40 × 18 + 10 × 2 + 5 = 745
```

The resulting  list is  the list  of `num_s2g`  for the  specific full
paths. We just have to add `first_num` and the final list contains the
`num` keys for specific full paths.

```
 35 = 10 ×  3 + 5 → (3,5) → (3,2,5) → 1800 + 40 × 3 + 10 × 2 + 5 = 1945
 45 = 10 ×  4 + 5 → (4,5) → (4,2,5) → 1800 + 40 × 4 + 10 × 2 + 5 = 1685
 55 = 10 ×  5 + 5 → (5,5) → (5,2,5) → 1800 + 40 × 5 + 10 × 2 + 5 = 2025
...
134 = 10 × 13 + 4 → (13,4) → (13,2,4) → 1800 + 40 × 13 + 10 × 2 + 4 = 2344
136 = 10 × 13 + 6 → (13,6) → (13,2,6) → 1800 + 40 × 13 + 10 × 2 + 6 = 2346
...
185 = 10 × 18 + 5 → (18,5) → (18,2,5) → 1800 + 40 × 18 + 10 × 2 + 5 = 2545
```

### Second Part of the List

Computing `num_s2g=2` for the specific  regional path and `num=45` for
the generic full path is the same as for the first part.

There are  10 080 generic  full paths, so we  first build the  list of
shifts:

```
-20000 -10000 -9000 -8000 ... -2 -1 1 2 ... 9 10 20 ... 90 100 200 ... 900 1000 2000 ... 9000 10000 20000
```

We add `num=45`, which gives:

```
-19955 -9955 -8955 -7955 ... 43 44 46 47 ... 54 55 65 ... 135 145 245 ... 945 1045 2045 ... 9045 10045 20045
```

The programme applies the `1..10080` window, which gives:

```
5 15 25 35 36 37 38 39 40 41 42 43 44 46 47 ... 54 55 65 ... 135 145 245 ... 945 1045 2045 ... 9045 10045
```

This gives the list of `full_num`  to look for in the `Path_Relations`
table and the list of `num` to  look for in the `Full_Paths` view. The
`Path_Relations` table provides the `coef2` number (the others are not
needed) and the `Full_Paths` view  provides the `first_num` field. For
each generic full path, we compute the formula:

```
n = first_num + coef1 × x + coef2 × y + z
x = 0
y = num_s2g
z = 0
```

That is, actually, the formula `n = first_num + coef2 × num_s2g`.

|          | Full_Paths | Path_Relations |   specific     |
|---------:|:----------:|:--------------:|:--------------:|
| full_num | first_num  |      coef2     |   full path    |
|    5     |    209     |       52       |      313       |
|   15     |    547     |       52       |      651       |
|   25     |   1223     |      104       |     1431       |
|  ...     |   ...      |      ...       |      ...       |
| 10045    |  1113361   |        1       |   1113363      |

The result of  the list of keys `num` for  the generated specific full
paths.

Conclusions for the Fourth Variant
----------------------------------

As before,  the running  time for `gener1.raku`  has not  changed much
from a variant to the next. A limited slow-down for some maps, nothing
special. So let us take a look at `gener2.raku` instead.

For maps `brit0` and `brit1`, doomed to fail, there is no change.

More  curious, there  is no  change either  for map  `frreg`. This  is
easily explained when you notice that there are 210 generic full paths
for 210  specific full paths: each  generic full path groups  a single
specific path.  This can be  explained in turn  by the fact  that each
Y2015-region contains  1, 2  or 3  Y1975-regions and  the optimisation
works only when a  big area contains at least 4  small areas (and even
then,  it is  not  always  the case).  So  in  `frreg`, each  specific
regional path  is associated with  a different generic  regional path.
The  optimisation introduced  in  version 4  gave  no improvement  for
`frreg`,  but  on  the  other  hand it  did  not  worsen  the  current
situation.

With map `fr1970`,  on the other hand, the  improvement is tremendous.
With version 3, I  killed the process after 2 hours  and a half, there
were  177 600 specific  full paths  generated up  to this  point. With
version  4, the  programme  ran  for 9  minutes  and generated  10 080
generic  full  paths, representing  1 114 960  specific  paths. If  we
compare the aborted run of version 3 with version 4, the first 179 063
specific  paths, embodied  by 1500  generic paths,  were processed  in
about 50 seconds.

For map  `mah2`, there is  also a big  improvement, even if  version 3
successfully generated  all 122 720 specific full  paths without being
interrupted.  These 122 720  paths were  generated  in 1  hour and  40
minutes. But version  4 ran for just 13 seconds  and generated all 484
generic  paths  corresponding  to  these  122 270  specific  paths.  A
460-fold improvement!

For maps  `brit2` and `mah1`,  the improvement was  also a big  one in
relative values, yet a small one in absolute values. Version 3 spent 3
minutes generating the 6840 full paths for `brit2` and spent 4 minutes
to generate the 13 646 full paths for `mah1`. Version 4 spent only 2.6
seconds to  generate the 36  generic full  paths for `brit2`  and only
0.95 second to generate the 38 generic paths for `mah1`.

On the other hand, nothing is fixed for map `fr2015`. During the third
attempt, I interrupted the process  after more than 8 hours, 1 037 600
full paths  having been  generated. For version  4, I  interrupted the
process  after  20  minutes,  when  78 400  generic  full  paths  were
generated.  These 78 400  generic paths  are equivalent  to 93 490 098
specific paths.  For map `fr2015`,  there are 894 macro-paths,  220 of
them  fruitless. When  I  killed  the process  after  20 minutes,  the
currently  processed macro-path  was the  7th macro-path  out of  894.
Doing a  rule of three,  we guess we  would end with  about 10 012 800
generic  paths. The  optimisation aiming  at reducing  the combinatory
explosion has  divided the number  of database records by  100 (78 400
instead of 93 millions), but the combinatory explosion is still there.

Fifth Version
=============

The  third  attempt aimed  at  avoiding  the processing  of  fruitless
macro-paths. The  optimisation with fruitless borders  was successful,
but not  completely. There are still  a few macro-paths which  fail to
generate full paths,  while not being bordered by  a fruitless border.
Why?

![Borders between Île-de-France, Burgundy and Champagne-Ardenne](IDF-CHA-BOU.png)

In map `fr1970`, let us look  at the Eastern part of Île-de-France and
its links  with Burgundy  and Champagne-Ardenne.  The single  point of
contact from `CHA` to `IDF` is department `77` (Seine-et-Marne). Also,
the single point of contact from  `BOU` to `IDF` is `77`. What happens
with a macro-path `%CHA  → IDF → BOU%` (or the  other way around)? The
full  path enters  `IDF` through  `77`, visits  all other  departments
within  `IDF` and  exits to  `BOU` through  `77`. This  cannot happen,
department `77` cannot be visited twice in an Hamiltonian path.

Being a single point of contact is not a problem. What is a problem is
being a single point  of contact for two regions or  more. This is the
case for `77` with `BOU` and `CHA`, this is the case for `03` (Allier)
with `BOU`  and `CEN` (Centre)  and this is  the case for  `27` (Eure)
with  `IDF`, `CEN`  and  `BNO` (Lower  Normandy).  Therefore, all  the
following macro-paths will be flagged as fruitless:

* `%BOU → IDF → CHA%`
* `%CHA → IDF → BOU%`
* `%CEN → AUV → BOU%`
* `%BOU → AUV → CEN%`
* `%BNO → HNO → CEN%`
* `%BNO → HNO → IDF%`
* `%CEN → HNO → BNO%`
* `%CEN → HNO → IDF%`
* `%IDF → HNO → BNO%`
* `%IDF → HNO → CEN%`

A special case, which happens many times in map `frreg`: if a big area
contains  only one  small area,  this  small area  is automatically  a
single point of  contact for all neighbour regions, yet  this is not a
problem. For example, the `BRE` small  area is single point of contact
for both  `NOR` (Normandy) and `PDL`  (Pays de la Loire),  but it does
not prevent the  macro-paths `%NOR → BRE → PDL%`  from generating full
paths  `%HNO →  BNO →  BRE →  PDL%`. These  "trivial single  points of
contacts" will not trigger a fruitless flagging.

![Excerpt from the frreg map with Bretagne, Pays de la Loire, Centre-Val-de-Loire and Île-de-France](BRE-CEN-IDF-PDL.png)

I know  that this new optimisation  will not solve the  problem of the
combinatory   explosion  of   `fr2015`,  but   I  will   implement  it
nevertheless.

Implementation
--------------

To  implement  this  optimisation,  I take  the  `Exit_Borders`  view,
upgrade it to a real table and  I add a new column `spoc`, for "single
point of contact". Actually, the meaning is rather "non-trivial single
point of  contact". In map `fr1970`,  this field will contain  `1` for
`(77,BOU)`, `(77,CHA)`, `(27,IDF)`, `(27,CEN)`,  `(27,BNO)` and so on.
But in map `frreg`, it  will still be `0` for`(BRE,NOR)`, `(BRE,PDL)`,
`(IDF,NOR)`, `(IDF,HDF)` and so on,  because these are trivial spoc's.
On the other hand,  the `spoc` column will be filled  with `1` for map
`frreg`  and for  `(PIC,NOR)`,  `(PIC,IDF)`  and `(PIC,GES)`,  because
Picardy  is  a  non-trivial  single point  of  contact  for  Normandy,
Île-de-France and Grand-Est.

To keep the code readable, the table `Exit_Borders` will be updated in
three steps.

1. A `select distinct`, as in the benchmark programme for the second version,

2. An  `update` with a  `select count(*)` sub-request, to  fill `spoc`
with `1` for both trivial spoc's and non-trivial spoc's.

3. Another `update` to fill back `spoc` with `0` for trivial spoc's.

To  identify the  fruitless macro-paths,  we  use a  self-join on  the
`Exit_Borders`  table.  Until  now,   the  "obvious"  direction  of  a
`Exit_Borders` record was to start from the small area `from_code` and
to stop  at the big  area `upper_to`. For  this self-join, one  of the
`Exit_Borders`  records  is  crossed   backwards  from  the  big  area
`upper_to` to  the small  area `from_code` and  then the  other record
takes over  and is  crossed in  the natural  way, from  `from_code` to
`upper_to`.

Actually, I  think that there is  no need to separate  the `update` in
step 3 from the `update` in step 2. If I add comments, the readability
is kept.

With  this fifth  version, I  add a  `fruitless_reason` column  to the
`Maps` table, to summarise all the `fruitless_reason` columns from all
the  macro-paths belonging  to the  map.  This field  stores both  the
fruitless borders  from the  third variant  and the  fruitless triples
from  the fifth  variant. This  field is  not used  in the  extraction
programmes, its  only use is to  be displayed in the  webpages showing
the  map (macro  or full).  The  fruitless borders  and the  fruitless
triples are displayed  in one direction only, that is,  if the webpage
displays the fruitless part `A → B`, it will not display the part `B →
A`.

Conlusions for the Fifth Variant
--------------------------------

For `gener1.raku`,  there are some processing  time changes, sometimes
accelerating, sometimes slowing, but they are not significant.

Likewise, for  `gener2.raku`, most  of the  time, the  processing time
changes are not significant. Only for `fr1970` and `frreg` the changes
deserve an analysis.

The  fifth variant  aimed at  reducing the  number of  macro-paths for
`fr1970`. It worked, the number  of macro-paths with `fruitless` equal
to `0` went down from 174 to  42. Yet, the processing time was more or
less the same, about 8 minutes and half.

For `frreg`, the reduction of processing time was very significant (in
relative values; in absolute value,  it was not really noticeable). In
the fourth version,  no macro-path was flagged  with `fruitless` equal
to `1`. In the fifth version,  790 macro-paths out of 894 were flagged
as `fruitless` and the processing time fell down from 57 seconds to 18
seconds.

As for map `fr2015`, the combinatory explosion is still there, but we
already knew that.

Back to map `fr1970`. Among all macro-paths, 42 remain with `fruitless
= 0`, but only 2 of them give full paths. Why?

![Lower-Normandy, Britanny and Pays de la Loire](BNO-BRE-PDL.png)

We know that the beginning and the end of a full path belong to region
`PAC`      (Provence-Alpes-Côte-d'Azur)      and     region      `NPC`
(Nord-Pas-de-Calais).  Therefore Britanny  (`BRE`)  is a  pass-through
region, not a begin or end region. Any macro-path contains either `BNO
→ BRE →  PDL`, or `PDL →  BRE → BNO`. To keep  the discussion shorter,
let us  consider only `BNO  → BRE →  PDL`, which gives  21 macro-paths
with  `fruitless =  0`, and  only  a single  macro-path yielding  full
paths. Extending  this path part to  the next region will  give either
`BNO → BRE → PDL → CEN` or `BNO → BRE → PDL → PCH`.

Now, let us examine how each region  can be replaced by a region path.
Region `BNO` can be replaced by  two region paths, both of them ending
in `50`. Therefore, the  part `BNO → BRE → PDL` gives `xxx  → yyy → 50
→→ BRE → PDL`. Then we have  no choice for `BRE`, which gives the part
`xxx → yyy  → 50 → 35 → 22  → 29 → 56 →→ PDL`.  Starting from `56`, we
have only two region paths in `PDL`: `44 →  85 → 49 → 72 → 53` and `44
→ 85  → 49 →  53 → 72`.  The first one can  link to neither  `PCH` nor
`CEN`. The second one can link  to `CEN` but not `PCH`. The conclusion
is that a macro-path containing `%BNO →  BRE → PDL → CEN%` can produce
full paths,  but a  macro-path containing  `%BNO → BRE  → PDL  → PCH%`
cannot. The database  stores 370 macro-paths containing `%BNO  → BRE →
PDL → CEN%`, only one of which  having `fruitless = 0`. It stores also
1380 macro-paths  containing `%BNO →  BRE → PDL  → PCH%`, 20  on which
having `fruitless = 0`.

Is it possible to flag these  macro-paths linking `PDL` to `PCH`? Yes,
but  this  would  require  a  first  request  generating  all  partial
macro-paths with 4 regions and 3  arrows. This first request would use
a join:

   Big_Borders → Big_Borders → Big_Borders
   Big_Borders ⟗ Big_Borders ⟗ Big_Borders

We would  need a second request  generating all extracts in  which the
middle regions can be replaced by region paths. This request would use
a join:

  Exit_Borders (backward) ⟗ Region_Paths ⟗ Small_Borders ⟗ Region_Paths ⟗ Exit_Borders

And the programme  would extract the difference  (`except` in SQLite).
This seems to be much work for  a small gain. Yet, this shows that the
fifth version  could have  been more general  by ignoring  the "single
point  of contact"  property.  We would  build  all possible  extracts
containing 3 regions and 2 arrows with a request using this join:

   Big_Borders → Big_Borders
   Big_Borders ⟗ Big_Borders

We would then build extract with a request usging this join:

  Exit_Borders (backward) ⟗ Region_Paths ⟗ Exit_Borders

And we would extract the difference to flag macro-paths with `fruitless = 1`.

But for the moment, I will  not implement this adaptation. It does not
bring much  and it would  be better  to find a  new way to  reduce the
combinatory explosion, which still rages on `fr2015`.

Hamilton's Icosian Game
=======================

As most of us know, a path that uses all edges of a graph is called an
"Eulerian path". That refers to the  anecdote of Euler wondering if it
was possible to visit the town  of Königsberg, while crossing once and
only once each one of the seven main bridges on river Pregel.

But why, at the same time, are paths visiting once and only once every
node  called "Hamiltonian  paths"?  You  can find  the  answer on  the
Internet, but I found it in a paper-printed book in French,
[tome 2 of Mathematical Recreations by Édouard Lucas](https://gallica.bnf.fr/ark:/12148/bpt6k39443/)
This book is available in electronic form on the website of
[Bibliothèque nationale de France](https://www.bnf.fr/).
All the discussion below comes from the
[chapter on the icosian game](https://gallica.bnf.fr/ark:/12148/bpt6k39443/f206.item)
and the
[end notes](https://gallica.bnf.fr/ark:/12148/bpt6k39443/f243.item).

Sir William Rowan Hamilton is  the mathematician who invented  quaternions, an extension
of the concept  of complex numbers. Starting from complex  number _a +
bi_ with _i²  = -1_, he invented new  numbers _a + bi + cj  + dk_ with
_i² = -1_, _j²  = -1_ and _k² = -1_. According  to Lucas' endnotes, he
tried other methods to extend the  complex numbers, one of which using
the isometric  transformations of the  dodecahedron. A side  effect of
this work is a game, played  on a wooden dodecahedron. At each vertex,
a short  nail is protruding  from the wooden dodecahedron.  The player
ties a string on a first nail,  draws this string along an edge, loops
around the nail at the end of the edge, draws the string along another
edge, loops around  the next nail and so on,  visiting all nails until
he comes back to the starting nail. You have recognised the concept of
Hamiltonian cycle, which can be extended to the concept of Hamiltonian
path.

The game  is a  purely topological  one. So  we do  not need  a wooden
dodecahedron, we can play on a
[flat drawing](https://gallica.bnf.fr/ark:/12148/bpt6k39443/f218.item)
which shows a graph similar to  the graph of dodecahedron vertices and
edges.  Since a  dodecahedron has  20  vertices, and  since the  latin
alphabet  contains 20  consonants,  Lucas tagged  each  vertex with  a
consonant and then
[developped this naming](https://gallica.bnf.fr/ark:/12148/bpt6k39443/f216.item),
by  using  the name  of  a  famous city  whose  initial  was the  said
consonant. The association between the  dodecahedron and the cities is
purely arbitrary  and does not  respect the geographical  positions of
the cities. For example, you can  see that the shortest path from Rome
to Naples is through Stockholm.

I took Lucas' notation  for the Small Areas of a  new `ico` graph. The
Icosian game does  not provide a second level which  would give me the
Big Areas. So I  decided to group all 20 cities in  a single Big Area.
This allows me to test the special case of a graph containing a single
Big Area.  This special case  was accounted for in  the specifications
and hopefully in the code, but never tested until now.

There  are 120  isometries  for  the dodecahedron.  You  can move  the
dodecahedron so any one of the 20 nodes can be brought to the position
initially occupied by node `B`. Then with a rotation around axis `BT`,
you can bring any neighbour to the position initially occupied by node
`C`. Then something  you cannot do with a wooden  dodecahedron or (for
role-playing  gamers)  with  a  D12, you  can  turn  the  dodecahedron
inside-out like a sock. That gives 20 × 3 × 2 = 120 isometries.

There are 3240 regional paths and 3240 full paths. Yet, because of the
isometries, there are only 3240 /  120 = 27 really different paths. We
can define 27 canonical paths beginning with  `'B → C → D%'`, apply an
isometry and obtain any path among the 3240 possible paths.

To generate  the 120 isometries,  Lucas (or is it  Hamilton?) suggests
the use of three basic isometries, a pentagonal rotation, a triangular
rotation and a mirror symmetry. All isometries of the dodecahedron are
combinations of these three basic isometries.

The pentagonal  rotation is named  λ (lambda). It rotates  the `BCDFG`
pentagon around its centre.

![Rotation λ](rotation-lambda.webp)

The  triangular   rotation  is  named   κ  (kappa).  It   rotates  the
dodecahedron around the `CV` axis, so that `B` ends at `D`'s position,
`D` ends at `P` and `P` ends at `B`.

![Rotation κ](rotation-kappa.webp)

According to  Lucas' text, symmetry  ɩ (iota)  swaps `B` with  `C`. In
other words, it is a symmetry  over the plane containing `F`, `K`, `Q`
and `R`.

![Symétrie ɩ](symetrie-iota.webp)

Mathematical and Epistemological Interlude
------------------------------------------

Isometries  are  mathematical  functions,  so  I  should  use  Euler's
functional notation  `y =  f(x)` or  in this case,  for example,  `Z =
λ(H)`. But I will not do this. Here is the reason why.

We  live in  a world  where  the Second  Law of  Thermodynamics is  in
effect, which  differentiates the  future from the  past and  gives an
arrow  to Time.  On an  other topic,  my mother  language and  all the
foreign  languages I  have  learned are  written  left-to-right. As  a
consequence,  nearly  all  the  time   diagrams  and  nearly  all  the
chronological charts I  have seen are drawn with the  past on the left
and the future on the right.  Very rarely, I see a chronological chart
drawn as a spiral  or a time diagram where the  time axis is vertical.
But I have  never seen a diagram or chart  drawn horizontally with the
past on the right and the future on the left <a href='#note'>(*)</a>.

When  we cascade  isometries,  for  example λ  and  _then_ ɩ,  Euler's
functional notation would give:

```
Z = λ(H)
P = ɩ(Z)
  = ɩ(λ(H))
```

One consequence  of this is  that the  syntax for the  circle operator
(combination of two functions) for λ and _then_ ɩ is "ɩ o λ", although
λ is the first function and ɩ is the second one. So, with both "ɩ o λ"
and "ɩ(λ(H))", the chronological order must be read right-to-left, the
opposite of the conventions and usages  in the part of the world where
I live.

Some mathematicians  will explain  that the  universe of  the abstract
mathematical concepts does  not obey the second  law of thermodynamics
and  that it  does  not  contain the  concept  of  time, that  nothing
_happens_, eveything _permanently exists_. But for pupils and students
learning  mathematics, it  is very  useful to  build mental  images of
these mathematical concepts and  to imagine that these representations
evolve while the time flows.

And then, when switching from mathematics to computer programming, the
notion of time  flow is reintroduced by necessity, because  of the way
the computers work.

In  computer  programming,  one  of the  benefits  of  object-oriented
programming is  to reinstall  the left-to-right representation  of the
flow of  time, when  invoking several methods  sequentially. Supposing
that the nodes  `B` to `Z` are  instances of an object  class and that
isometries `λ`, `κ` and `ɩ` are  methods from this class, invoking `λ`
and _then_ `ɩ` to node `H` would give:

```
resultat = H.λ.ɩ;
assert( resultat == P);
```

So I will use this notation in the following documentation.

<a name='note'>(*)</a>
Actually, I  _saw_ a chronological chart  in which the past  is on the
right and  the future is  on the left. In  the Louvre Museum  in Lens,
there is a long rectangular hall in which the art works are arrayed in
chronological order. Let us suppose we enter at the "Antiques" end and
we look toward the "contemporary" end. If we turn our head to the left
and if  we look up, we  find on the wall  some chronological markings,
relative to  the art works nearby. On this  wall, the markings  show a
chronological order  from left to  right. If we  turn our head  to the
right  and  if  we look  up  at  the  facing  wall, we  see  the  same
chronological markings. But this time, they show a chronological order
from right to left. This is an  exception to the general rule that any
horizontally drawn chronological  chart is drawn with the  past on the
left side and with the future on the right side, but this exception is
justified and it does not void the general principle.

Implementation
--------------

I use the OO notation in the documentation, but not in the programmes.
Although isometries  are mathematical functions, I  will not implement
them as  programming functions. An isometry  will be a string  such as
`λɩ` and we  will have a programming function named  `↣` which is used
in this way:

```
my Str $resul1 = 'M' ↣ 'λɩ';
my Str $resul2 = 'M' ↣ 'λ' ↣ 'ɩ';
if $resul1 eq $resul2 {
  say "it works!";
}
else {
  say "there is a problem somewhere: $resul1 vs $resul2";
}
```

Remark.  The  char  I  use  for  this  operation  is  `U+21A3  =  "↣"`
(rightwards arrow  with tail) instead of  `U+2192` (rightwards arrow),
because recent  versions of  Raku use  `U+2192` in  their syntax  as a
short  version of  `->`. On  the  other hand,  the strings  describing
Hamiltonian  paths still  use `U+2192  = "→"`,  there is  no confusion
problem with the Raku syntax.

Yet, I need some additional data  for each isometry. Until this point,
I have implemented everything as SQL  tables, I will continue with the
dodecahedron isometries.  So we  have an  `Isometries` table  with the
following fields.

* `map` is  the first part  of the  record key, because  the programme
will compute isometries  for the graphs describing  the other Platonic
solids.

* `isometry` is the second part of the record key. It is a string with only chars `λ`,
`κ`  and `ɩ`,  describing  how  the isometry  derives  from the  basic
isometries. Of course,  the string is read  left-to-right according to
the usual  representation of the  flow of  time. One exception  is the
identity isometry. For the identity, the key is `Id`.

* `transform`.  This  field  shows  how  the  `B`  to  `Z`  codes  are
transformed by the isometry. This transformation is computed with:

```
        $resul .= trans("BCDFGHJKLMNPQRSTVWXZ"
                    =>  $transform);
```

For example, with rotation `λ`, the transformation is computed with:

```
        $resul .= trans("BCDFGHJKLMNPQRSTVWXZ"
                    =>  "GBCDFKLMNPQZXWRSTVJH");
```

* `length` is the number of basic isometries used to build the current
isometry. This is zero for `Id`,  this is the length of the `isometry`
field for the other isometries.

* `recipr`  is the  transformation string  to "undo"  what `transform`
would do. Previously, this was the key of the reciprocal isometry.

* `involution` is a boolean showing whether the isometry is involutive or
not. An involution is a function  equal to its reciprocal. This is the
case with symmetries. No longer used.

Another new table  is `Isom_Path`, storing the  way dodecahedron paths
derive from  canonical paths (that  is, paths starting  with `B →  C →
D`). The table has four fields:

* `map`, first part of the key, as with all other tables,

* `canonical_num`: the key from the canonical Regional Path.

* `num`: the key from the actual Regional Path

* `isometry`:  the `isometry`  field of  the isometry  that turns  the
canonical path into the actual path.

* `recipr`: the `isometry` field of the isometry that turns the actual
path  into the  canonical  path. Previously,  it was  the  key of  the
reciprocal isometry. No longer used.

Note: there is  no need to store  the other key fields  of the `Paths`
table: `level` and `area`. Their values are constant: `2` and `"ICO"`.

To feed  the isometry table, for  each isometry, we want  the shortest
string of  basic isometries.  As is  written in  _Mastering Algorithms
with Perl_, which I
[mentionned previously](#user-content-fifo-or-lifo),
we  need to  use  a  FIFO structure.  So  building  the isometries  is
achieved with the following process.

1. The  programme initialises  the `Isometries` table  with hard-coded
values for `Id`, `λ`, `κ` and `ɩ`.

2. The `to-do` list is initialised with isometries `λ`, `κ` and `ɩ`.

3. Begin a loop on `to-do`.

4. Inner loop on the basic isometries `λ`, `κ` and `ɩ`.

5. The programme catenates the isometry from the `to-do` list with the basic isometry.

6. The programme computes the `transform` field for the new isometry.

7. The programme checks if the `Isometries` table already contains an isometry with the same `transform` value.

8. Upon failure of this search, the programme stores the new isometry into the table and at the end of the `to-do` list.

9. End of iteration for both loops. If the `to-do` list is empty, end of the loop.

To fill the field `recipr` (and also the field `involution`), the programme
computes the  field `transform` for  the reciprocal isometry  and uses
this value to extract the reciprocal  isometry from the table. But how
is this `transfom` value computed?

Let us consider rotation `λ`. Transforming a node or a path is done with:

```
        $resul .= trans("BCDFGHJKLMNPQRSTVWXZ"
                    =>  "GBCDFKLMNPQZXWRSTVJH");
```

For the reciprocal rotation, we would just do:

```
        $backward .= trans("GBCDFKLMNPQZXWRSTVJH"
                       =>  "BCDFGHJKLMNPQRSTVWXZ");
```

So the `transform` field for the reciprocal of rotation `λ` is computed with:

```
        $back-lambda  =       "BCDFGHJKLMNPQRSTVWXZ";
        $back-lambda .= trans("GBCDFKLMNPQZXWRSTVJH"
                          =>  "BCDFGHJKLMNPQRSTVWXZ");
```

If the  value of `back-transform` calculated  in this way is  equal to
the value  of `transform` for  the currently processed  isometry, that
means that the isometry is its  own reciprocal, in other words this is
an involution.  The programme feeds  the column `involution`  with `1`
and stores the isometry.

If the value of `back-transform` can be found as the `transform` field
of an  already created isometry, the  new isometry is stored  into the
database with the code of the previous isometry in the `recipr` field.

If the `back-transform` value cannot be  found in the database for the
already  existing isometries,  the  new isometry  is  stored into  the
database  with  the `involution`  field  temporarily  filled with  the
out-of-bounds value  `-1` and with  the `recipr` field  containing the
value of `back-transform`. Then, after all isometries are created, the
programme will  mop up the isometries  with `involution = -1`  to give
them  the  actual  code  of  the reciprocal  isometry  (and  set  back
`involution` to zero).

Of course, I could have added  an `update` statement each time I store
an  isometry whose  reciprocal is  known, to  fill the  missing fields
`involution` and `recipr` in this already known isometry. But I prefer
update all those  44 isometries in one single  `update` statement than
running an  `update` statement 44 times  to update a single  record at
each iteration.

Filling table `Isom_Path` is a small matter of programming.

### Problem

Actually,  what is  written above  is not  completely right.  Remember
rotation λ:

![Rotation λ](Lambda.png)

Now, let us consider rotation κ followed by rotation λ. With the method
described above, this gives:

![Rotations κ then λ, old version](Kappa-Lambda-old.png)

As  you can  see, rotation  λ  does not  really apply  to the  central
pentagon  (as the  dodecahedron is  represented), but  to the  (BCDFG)
pentagon,  wherever it  is. This  does not  match with  what we  would
think.  We would  think  that rotation  λ would  always  apply to  the
central pentagon, no matter which nodes it holds:

![Rotations κ then λ, new version](Kappa-Lambda-new.png)

There is still a problem,  computing the reciprocal isometry no longer
works. Rotation λ uses the new position of pentagon (BCDFG) instead of
the  central pentagon,  rotation κ  uses the  new position  of node  C
instead of the old one, currently occupied by P, symmetry ɩ (not shown
below)  uses the  oblique axis  (KFQR)  instead of  the vertical  axis
(GBST).

![Rotations κ and λ for the reciprocal isometry](Kappa-Lambda-after.png)

Therefore, I  remove from programme `gener-isom.raku`  the computation
of reciprocal isometry and of  field `involution`. Field `recipr` will
still be used to store the  string used for the reverse transformation
of strings. So  `recipr` is similar to `transform`, which  is used for
direct transformation of strings.

### Implementation

The  computation of  isometries uses  arrays showing  how the  various
dodecahedron  nodes  "travel"  when successive  basic  isometries  are
applied.  After rotation  λ,  B  is located  in  C's  former place,  C
replaces D, G replaces B, H replaces Z and so on, so:

```
@transf-lambda = <1 2 3 4 0 19 18 5 6 7 8 9 10 14 15 16 17 13 12 11>;
```

On the same way, we have:

```
@transf-kappa = <2 1 11 10 9 8 15 14 13 12 19 0 4 5 18 17 16 6 7 3 >;
```

![Arrays of indexes for isometries λ, κ and κλ](Kappa-Lambda-arrays.png)

And for a composite isometry such as κλ, we have:

```
@list = <3 2 9 8 7 6 16 15 14 10 11 1 0 19 12 13 17 18 5 4 >;
```

These various arrays allows us to build the transformation strings:

```
%trans<λ>  = "GBCDFKLMNPQZXWRSTVJH";
%trans<κ>  = "PCBZQRWXHGFDMLKJVTSN";
%trans<κλ> = "QPCBZXHGFDMNSTLKJVWR";
```

Other Platonic Solids
---------------------

Since I have created the dodecahedral  graph for the icosian game, why
not  create graphs  for the  other platonic  solids? These  graphs are
named PL _n_, where _n_ is the number of faces.

Just  like the  20 nodes  of the  dodecahedral graph  are named  after
cities  the initial  of  which is  a  consonant, the  6  nodes of  the
octahedral graph are named after cities  the name of which begins with
a vowel. In addition,  I have tried to set up these  cities in a place
consistent with their real  geographical locations: Anchorage near the
North pole, Ushuaia near the  South pole, Edmonton, Yaounde; Islamabad
and Osaka roughly near the equator.

For tetrahedron PL4, I took cities with initials A, B, C and D, set-up
in a place consistent with their real geographical locations. For cube
PL6, I have also tried to  follow the real geographical locations, but
I did  not try to use  a definite alphabetical scheme.  The names span
from  `B` for  Buenos  Aires to  `W` for  Wellington,  with many  gaps
between letters. As  for icosahedron PL20, I have used  12 cities from
`A`  for Amsterdam  to `L`  for London,  but without  adhering to  the
geographical locations.

Graphs  PL4, PL6  and PL8  show the  corresponding platonic  solids in
oblique  projection.  On   the  other  hand,  graph   PL20  shows  the
icosahedron  in  a   polar  projection,  like  graph   `ico`  for  the
dodecahedron. Actually, I copied one of the graph drawings I found on the
[Wolfram website](https://mathworld.wolfram.com/IcosahedralGraph.html).

Running the regional paths  and macro-paths generation (`gener1.raku`)
is  nearly instantaneous  for  PL4, PL6  and PL8.  But  for PL20,  the
generation ran for 35 minutes, with  about 2 minutes to generate 75840
regional paths  and about  33 minutes to  renumber these  75840 paths.
Then the generation  of generic full paths,  `gener2.raku`, was nearly
instantaneous, including for  PL20. We could have  guessed so, because
these full graphs contains only one big area each.

We can  define basic isometries  and compute composite  isometries for
those  Platonic solids,  just like  was  done for  the Icosian  game's
dodecahedron.

Elementary Graphs
=================

Programme `init-elem.raku` creates a  few elementary graphs, according
to  a  number   _n_.  Here  are  possible  graphs,  using   _n_  =  5.
Extrapolation  to other  _n_ numbers  is left  as an  exercise to  the
reader.

* [complete graph](https://mathworld.wolfram.com/CompleteGraph.html)
K5, with 5 nodes and 10 edges,

* [empty graph](https://mathworld.wolfram.com/EmptyGraph.html)
K-bar 5, with 5 nodes (all isolated) and 0 edges,

* [path graph](https://mathworld.wolfram.com/PathGraph.html)
P5, with 5 nodes and 4 edges,

* [cycle  graph](https://mathworld.wolfram.com/CycleGraph.html)
C5, with  5 nodes  and 5  edges, actually  a pentagon,

* [star graph](https://mathworld.wolfram.com/StarGraph.html)
S6, with 6 nodes and 5 edges,

* [wheel graph](https://mathworld.wolfram.com/WheelGraph.html)
W6, with 6  nodes and 2 × 5 =  10 edges (5 edges for the  spokes and 5
edges for the rim),

* [prism graph](https://mathworld.wolfram.com/PrismGraph.html)
Y5, with 2 × 5  =10 nodes and 3 × 5 = 15 edges, representing a
[geometrical prism](https://mathworld.wolfram.com/Prism.html)
in which both bases are pentagons,

* [antiprism graph](https://mathworld.wolfram.com/AntiprismGraph.html)
AY5, with 2 × 5 = 10 nodes and 4 × 5 = 20 edges, representing a
[geometrical antiprism](https://mathworld.wolfram.com/Antiprism.html)
in which  both bases are  pentagons.  "AY" is not  a standard
notation, it is a personal extension  to the "Y" standard notation for
prism graphs.

* a few other graphs suggested by Wolfram, including
[crossed prism graph](https://mathworld.wolfram.com/CrossedPrismGraph.html)
(which is impossible if _n_ is odd),
[helm graph H5 en](https://mathworld.wolfram.com/HelmGraph.html),
[simple ladder graph L5](https://mathworld.wolfram.com/LadderGraph.html)
[Möbius ladder graph M5](https://mathworld.wolfram.com/MoebiusLadder.html),
[web graph](https://mathworld.wolfram.com/WebGraph.html).

Here are the graphs I have decided to generate:

![Elementary graphs for n=5](Elementary-graphs.png)

The  complete  graph  K5  is  not generated,  because  the  number  of
Hamiltonian paths in  this graph would be the factorial  of _n_, which
may be  correct for _n_ =  5, but would  be huge for higher  values of
_n_.  Also,  the statistics  on  this  graph  are boring.  Radius  and
diameter are both 1, all nodes are central nodes.

The empty graph K-bar 5 (which I would have named "archipelago graph")
is  not generated  either, because  it  is even  less interesting.  No
Hamiltonian paths, infinite diameter,  no central nodes. "K-bar" means
letter "K" with an overbar. The reason  is that the empty graph is the
complement of the complete graph K5.

Usually,  the linear  graph P5  is drawn  with all  nodes horizontally
aligned. Here,  I have drawn this  graph as an incomplete  circle. The
first   reason  is   that   this  reduces   the   size  of   programme
`init-elem.raku`, the  code for P5  sharing many lines with  the other
graphs.  The  second reason  has  been  already described.  The  range
between the max  latitude and the min latitude should  not be zero, to
prevent a zero-by-zero division.

The star graph with 5 rays is named S6 by
[the Wolfram site](https://mathworld.wolfram.com/StarGraph.html)
because  it contains  6 nodes:  1 centre  node and  5 outlying  nodes.
Because of code factoring, this S6 graph is generated among all graphs
generated with  _n_ = 5.  It is  not very interesting.  No Hamiltonian
paths (except  when _n_  = 2), diameter  is 2, radius  is 1,  only one
central  node. The  Wolfram  website mentions  that  some authors  use
another  naming convention  for this  graph. So  the 5-ray  star graph
would be S5 instead of S6.

The wheel graph with 5 spokes is named W6 by
[the Wolfram website](https://mathworld.wolfram.com/WheelGraph.html)
for the same reasons as S6 and  I include it among the graphs with _n_
= 5 for  the same reasons. And the Wolfram  website mentions that some
authors prefer  give the name  W5 to the  5-spoke wheel graph  (with 6
nodes and 10 edges).

The Wolfram website gives several suggestions for the
[Prism graph](https://mathworld.wolfram.com/PrismGraph.html):
Y5, D5 or Π5, but it seems that the most used name is Y5, so I adopted
this one. On the other hand, the website gives no suggestions for
[Antiprism graphs](https://mathworld.wolfram.com/AntiprismGraph.html),
so I adopted AY5, which is the Prism graph with a "A" for "Anti" prefix.

As for  the other standard graphs  (ladders, helm, etc), they  are not
included in the generation programme. For the moment at least.

Generating some graphs  allows us to find some  well-known graphs. For
example, the  `W4` wheel graph is  similar to the `K4`  complete graph
and to the tetrahedron graph (which  I called `PL4`). Also, graph `Y4`
is  similar to  the geometrical  cube (aka  hexahedron, or  `PL6`) and
graph `AY3` is similar to octahedron (or `PL8`).

![Special elementary Graphs](Special-graphs.png)

Statistics
==========

A new feature has crept in, statistics!

Statistics on Hamiltonian Paths
-------------------------------

Below, I describe  statistics for regional Hamiltonian paths,  yet the definitions
can  extend to  macro-paths.  But, with  the way  the  full paths  are
implemented, no statistics will be computed for full paths.

Let us  begin with a stupid  example. In how many  regional paths does
department  `XXX` appear?  For  example, in  map  `fr2015` and  region
`IDF`,  in how  many Hamiltonian  paths does  department `78`  appear?
Well,  region  `IDF` has  800  Hamiltonian  regional paths,  therefore
department `78`  appear in  800 Hamiltonian regional  paths. Likewise,
region `NAQ` has 182  Hamiltonian regional paths, therefore department
`33`  appears in  182 Hamiltonian  regional  paths. This  is a  direct
consequence of the definition of Hamiltonian paths.

Two  other  examples  are  smarter  and  more  interesting.  How  many
Hamiltonian regional paths have `XXX` at one extremity (begin or end)?
In how many Hamiltonian regional paths does the border `XXX → YYY` (or
its opposite  `YYY → XXX`)  appear? These two statistics  are computed
and stored in tables `Areas` and `Borders`.

These statistics are usually more interesting than the first statistic
mentionned,  but  in some  special  cases  these statistics  can  give
uninteresting results.  For example,  if no Hamiltonian  regional path
has been generated for the big  area (unconnected graph, three or more
dead-ends,  other   reason),  then  the  statistics   will  give  zero
everywhere.  If the  big area  contains one  or two  small areas,  the
statistics will not  give interesting results. And in the  case of the
icosian game's dodecahedron,  all nodes are equivalent  to each other,
all edges are equivalent to each  other, so the statistics will give a
constant value for the nodes and another constant value for the edges.

Let us take the example of map `fr2015`, big area `IDF` and small area
`78`. Computing  the number  of regional paths  starting from  `78` or
stopping at `78` would be:

```
update Areas as A
set nb_region_paths = (select count(*)
                       from   Paths as P
                       where  P.map   = A.map
                       and    P.level = 2
                       and    (P.path like '78 → %'
                           or  P.path like '% → 78')
                       )
where  map   = 'fr2015'
and    level = 2
and    code  = '78'
```

or, if we want to avoid hard-coded values as much as possible:

```
update Areas as A
set nb_region_paths = (select count(*)
                       from   Paths as P
                       where  P.map   = A.map
                       and    P.level = 2
                       and    (P.path like A.code || ' → %'
                           or  P.path like '% → ' || A.code)
                       )
where  map   = 'fr2015'
and    level = 2
and    code  = '78'
```

But this formula does not work when a big area contains a single small
area, as with several areas of  map `frreg`. To allow for this special
casse, we would code:

```
update Areas as A
set nb_region_paths = (select count(*)
                       from   Paths as P
                       where  P.map   = A.map
                       and    P.level = 2
                       and    (P.path like A.code || ' → %'
                           or  P.path like '% → ' || A.code
                           or  P.path = A.code)
                       )
where  map   = 'fr2015'
and    level = 2
and    code  = '78'
```

Actually, there is a simpler SQL statement. Just write:

```
update Areas as A
set nb_region_paths = (select count(*)
                       from   Paths as P
                       where  P.map   = A.map
                       and    P.level = 2
                       and    A.code  in (P.from_code, P.to_code)
                       )
where  map   = 'fr2015'
and    level = 2
and    code  = '78'
```

This formula  is correct for  big areas  with several small  areas and
also for big areas containing a single small area.

For the borders statistics, the first idea it coding:

```
update Borders as B
set nb_paths = (select count(*)
                from   Paths as P
                where  P.map   = B.map
                and    P.level = 2
                and    (P.path like '%' || B.from_code || ' → ' || B.to_code   || '%'
                  or    P.path like '%' || B.to_code   || ' → ' || B.from_code || '%')
                )
where  map        = 'fr2015'
and    level      = 2
and    from_code  = '78'
and    to_code    = '95'
```

Remember that  for each  Hamiltonian path in  table `Paths`,  there is
another Hamiltonian path, which is  the backward version of the first.
So there are as many `%95 → 78%` paths as there are `%78 → 95%` paths.
So we can write:

```
update Borders as B
set nb_paths = 2 * (select count(*)
                    from   Paths as P
                    where  P.map   = B.map
                    and    P.level = 2
                    and    P.path  like '%' || B.from_code || ' → ' || B.to_code   || '%'
                    )
where  map        = 'fr2015'
and    level      = 2
and    from_code  = '78'
and    to_code    = '95'
```

What about big  areas containing a single small area?  These big areas
have no internal border, therefore no record to update.

The  only  drawback  is  that   it  reintroduces  the  ugly  star  for
multiplication purposes, while we were glad that Raku would accept the
proper Saint-Andrew cross `×`.

Actually,  the SQL  statement  above  contains a  tricky  bug. Let  us
suppose the  big area  contains small  areas `A`,  `AA`, `B`  and `BB`
among others. When  we compute the statistics for the  border `A → B`,
the SQL statement will extract not only the paths `xxx → A → B → yyy`,
but also the paths `xxx → AA → B → yyy`, `xxx → A → BB → yyy` and `xxx
→ AA → BB → yyy` (plus the cases  where `A` or `AA` is at the start of
the path and the cases where `B` or `BB` is at the end of the path).

To tell apart `A` from `AA` and `B`  from `BB`, the idea is to use the
pattern `% A → B %`, with  a space after the first percent and another
before the second percent. The filter would be:

```
and    P.path like '% ' || B.from_code || ' → ' || B.to_code   || ' %'
```

But this  filter rejects  the paths beginning with  `A` and  the paths
ending in `B`.  So the spaces are  added not only to  the pattern, but
also to the checked string:

```
and    ' ' || P.path || ' ' like '% ' || B.from_code || ' → ' || B.to_code || ' %'
```

More readable with programmatically superfluous parentheses:

```
and    (' ' || P.path || ' ') like ('% ' || B.from_code || ' → ' || B.to_code || ' %')
```

This  filter is  good even  for big  areas containing  only two  small
areas, in  other words big  areas with  only two Hamiltonian  paths of
length 1, `A → B` and `B → A`.

Displaying The Statistics
-------------------------

The statistics are displayed with an histogram. Suppose the big area
contains the following small areas:

| Code | nb_paths |
|:----:|---------:|
| AAA  |   23     |
| BBB  |   45     |
| CCC  |   98     |
| DDD  |   23     |
| EEE  |   64     |
| FFF  |   98     |

This will generate this histogram:

| nb_paths | nb | Codes    |
|---------:|---:|:---------|
|    23    |  2 | AAA, DDD |
|    45    |  1 | BBB      |
|    64    |  1 | EEE      |
|    98    |  2 | CCC, FFF |

And this  table (without column  _nb_) is displayed in  the statistics
webpage. In addition, the map  is displayed with a rainbow-like colour
scheme. Blue represents  the small areas with a  low statistical value
and red represents the small areas with a high statistical value.

Since the  number of  lines in  the histogram can  be higher  than the
number of  colours available for the  map, we must merge  lines in the
table to display  the corresponding small areas with  the same colour.
Merging  is done  in  a  way similar  to  Huffman  encoding, with  the
constraint that  only successive  lines can merge.  At each  step, the
programme examines all pairs of successive lines and computes how many
small  areas  the resulting  line  would  contain. And  the  programme
chooses  the merge  with the  fewer  small areas.  Then the  programme
loops,  unless the  table  contains as  many lines  as  the number  of
available colours.  The map can be  generated with 8 colours,  but for
the  example, suppose  that  only  2 colours  are  available. We  have
initially 4 lines, therefore we must execute two merges.

Initial Table :

| nb_paths | nb |
|---------:|---:|
|    23    |  2 |
|    45    |  1 |
|    64    |  1 |
|    98    |  2 |

First step, merging the two lines with "1":

| nb_paths | nb |
|:--------:|---:|
|    23    |  2 |
|  45..64  |  2 |
|    98    |  2 |

Second step, merging two lines with "2":

| nb_paths | nb |
|:--------:|---:|
|  23..64  |  4 |
|    98    |  2 |

The map will be generated with

| nb_paths | colour | codes              |
|:--------:|:------:|:-------------------|
|  23..64  |  blue  | AAA, BBB, DDD, EEE |
|    98    |  red   | CCC, FFF           |

Actually, a better grouping exists. We could have:

| nb_paths | nb | colour | codes         |
|:--------:|---:|:------:|:--------------|
|  23..45  |  3 |  blue  | AAA, BBB, DDD |
|  64..98  |  3 |  red   | CCC, EEE, FFF |

But we will keep the current algorithm.

The same  processing building an  histogram and then merging  lines is
executed for the statistics on the borders.

Statistics on Macro-maps
------------------------

Statistics on macro-maps use the  same ideas as statistics on regional
maps: we  count the number  of macro-paths  crossing this or  that big
border, or  starting from or  stopping as this  or that big  area. But
there is something new. We can  count all macro-paths, or we can count
only the macro-paths which generated  full paths. These two categories
are  stored in  different  database  fields, with  a  `_1` suffix  for
macro-paths with full paths and  without this suffix when counting all
macro-paths.  These  two categories  of  statistics  are displayed  in
different webpages.

Statistics on shortest paths
----------------------------

When you are  interested in drawing shortest paths (or
[geodesics](https://mathworld.wolfram.com/GraphGeodesic.html))
and computing distances in a  graph, very soon
you learn some standard notions such as
[graph diameter](https://mathworld.wolfram.com/GraphDiameter.html),
[graph radius](https://mathworld.wolfram.com/GraphRadius.html)
and [vertex eccentricity](https://mathworld.wolfram.com/GraphEccentricity.html).
These notions are readily accessible in the
[Perl 5 module `Graph.pm`](https://metacpan.org/dist/Graph/view/lib/Graph.pod).

In  this project,  the Raku  programme `shortest-path-statistics.raku`
calls this Perl  module, computes the path statistics  and stores them
into  tables `Maps`  and `Areas`.  These statistics  are displayed  in
another webpage.  The eccentricities are  displayed both in  the graph
picture (as colours) and in a  table, like it was done for Hamiltonian
paths statistics (see above).

For a full map, statistics  are stored into fields `full_diameter` and
`full_radius` of  table `Maps`  and into field  `full_eccentricity` of
table `Areas` (for departments, with `level = 2`).

For a  macro-map, statistics  are stored into  fields `macro_diameter`
and `macro_radius` of table  `Maps` and into field `full_eccentricity`
of table `Areas` (for regions, with `level = 1`).

For a regional  map, statistics are stored into  fields `diameter` and
`radius` of  table `Areas` (for  regions, with  `level = 1`)  and into
field `region_eccentricity`  of table  `Areas` (for  departments, with
`level = 2`).

For a reason I do not understand, module `Graph.pm` refuses to compute
the eccentricity, diameter and radius values for a graph with only one
node  and zero  edges.  Yet,  these values  could  be  given as  zero.
Actually, programme `shortest-path-statistics.raku` takes this special
case in account and stores  zeroes into the statistics without calling
`Graph.pm`.

On  the  other  hand,  with   unconnected  graphs,  I  understand  why
`Graph.pm` returns `undef` or `Inf`  (infinity) for these graphs. This
corner case is also dealt with,  by storing out-of-bound value -1 into
the statistical fields.

These statistics are displayed at the following webpages, depending on
their scope:

* http://localhost:3000/en/shortest-path/full/fr1970

* http://localhost:3000/en/shortest-path/macro/fr1970

* http://localhost:3000/en/shortest-path/region/fr1970/BOU

Another series  of webpages lists the  distances from a given  area to
all other areas  in the same graph. These distances  are not stored in
the database, they are computed on-the-fly by `Graph.pm`. Here are the
webpages for big area `BOU` and small area `21`:

* http://localhost:3000/en/shortest-paths-from/full/fr1970/21

* http://localhost:3000/en/shortest-paths-from/macro/fr1970/BOU

* http://localhost:3000/en/shortest-paths-from/region/fr1970/BOU/21

A last  series of webpages  displays the  shortest paths from  a given
start area to  a given stop area. These shortests  paths are displayed
in a  similar way to statistics  on Hamiltonian paths, with  a colored
map and with two tables. Addresses are:

* http://localhost:3000/en/shortest-paths-from-to/full/fr1970/21/29

* http://localhost:3000/en/shortest-paths-from-to/macro/fr1970/BOU/BRE

* http://localhost:3000/en/shortest-paths-from-to/region/fr1970/BOU/21/58

### Counting the Shortest Paths from an Area to Another Area

Like the distances from area A to area B, the counts of shortest paths
from  area A  to area  B  are not  stored  in the  database, they  are
computed  each time  a webpage  is accessed.  Here is  the computation
method, using the `HDF` to `OCC` shortest paths in map `fr2015`.

The first step is computing the  distance from `HDF` to `OCC`. This is
a standard  function of `Graph.pm`.  The distance is 4,  therefore the
shortest paths follow the pattern `HDF → X → Y → Z → OCC`.

As you can  see, all possible `X`  nodes are at distance  1 from `HDF`
and at distance 3 from `OCC`, all possible `Y` nodes are at distance 2
from both `HDF` and `OCC` and all possible `Z` nodes are at distance 3
from `HDF` and at distance 1 from `OCC`.

So, the  second step scans all  areas and computes the  distances from
each area to  both `HDF` and `OCC`. Depending on  the result, the area
is dispatched in various buckets:

![distances from HDF and from OCC](HDF-to-OCC.webp)

* `NOR`, `IDF` and `GES` (distance 1 from `HDF` and 3 from `OCC`) in bucket 1,

* `PDL`, `CVL` and `BFC` in bucket 2,

* `NAQ` and `ARA` in bucket 3,

* of course, `HDF` in bucket 0 and `OCC` in bucket 4,

* `BRE` (distances 2 and 3) and `PAC` (distances 4 and 1) are discarded.

The third step  consists in counting how many shortest  paths run from
`HDF` to such or such area. Counting is also done for crossed borders.
Let us  call these  counters `n1`.  This step  is executed  in several
iterations, according to ascending bucket numbers.

* For the start area, `HDF`, the counter is always 1.

* For a border between a bucket `n`  area and a bucket `n`+1 area, the
`n1` counter is the same as for the bucket `n` area.

* For a bucket `n` area, the `n1` counter is the sum of `n1` counters
from the borders between this area and the bucket `n`-1 areas.

Below is an illustration of the successive iterations.

![Third step for the HDF → OCC computation](HDF-to-OCC-a.png)

At the end of  the third step, we know the  overall number of shortest
paths from  `HDF` to  `OCC`, but  we do  not know  how this  number is
dispatched  among  the various  intermediary  areas  and borders.  The
fourth step is  used to compute this and store  it into counters named
`n2`. It is  executed according to descending bucket  numbers. Here is
the illustration of the fourth  step, followed by the explanations. Do
not puzzle  about the dots in  the picture, it is  just a disagreement
between Metapost and me.

![Fourth step for the HDF → OCC computation](HDF-to-OCC-b.png)

* For the stopping area `OCC`, the `n2`  value is the same as its `n1`
value.

* For a border between a bucket `n`  area and a bucket `n`+1 area, the
counter  `n2`  of  the  `n`+1  area  is  split  between  the  borders,
proportionally to the  `n1` values. Thus, counter `n2=4`  for `CVL` is
split into `n2=2` for `NOR → CVL`  and `n2=2` for `IDF → CVL`, because
the `n1` counter of these two  borders are the same for these borders.
Likewise, border  `NAQ → OCC`  has `n1=3` and  border `ARA →  OCC` has
`n1=4`, so the counter `n2=7` for  `OCC` will be split into `n2=3` for
`NAQ → OCC` and `n2=4` for `ARA → OCC`.

* For an area from bucket `n`, the counter `n2` is the sum of counters
`n2`  for the  borders  from  this area  to  bucket  `n`+1 areas.  For
example, `CVL  → NAQ` has  `n2=2` and `CVL →  ARA` has `n2=2`  too, so
`CVL` has `n2=4`.

You  may notice  that on  each horizontal  line, the  sum of  all `n2`
counters is a constant.

Map of Paris Subway
-------------------

As long as I  was interested only in Hamiltonian paths,  I set aside a
few maps  because they  were too  big and or  there were  obviously no
Hamiltonian paths.  Both reasons apply  to the Paris subway  map, with
more than 300 stops and in which most lines end in a dead-end station,
far  more than  the two-dead-end  limit for  a graph  with Hamiltonian
paths.

With shortest  path exploration,  maps with  many dead-ends  gain some
renewed interest.  This is why  I added the  Paris subway map  to this
repository.

I took a map  from late 2023 and I kept all subway  lines. I added all
RER lines (regional netwok) for their parts within Paris. For example,
line B extends from "Gare du Nord" to "Cité Universitaire", discarding
"La Plaine Stade  de France" and northward, as well  as "Gentilly" and
southward. The only exception is "La Défense", which is outside Paris,
yet  has  a connection  with  subway  line  1.  I also  added  walking
connections through  corridors. On the  other hand, I did  not include
tram lines  and train lines. For  reasons explained later, RER  line D
does not appear in the map.

RER  stations and  connecting subway  stations have  a 3-letter  code,
abbreviating the actual name. Subway stations located on a single line
have a  code consisting  of the  line number (2  digits) and  a letter
suffix (or sometimes a digit suffix  when the subway line has too many
stations; e.g.  line 7 ends with  `070` = "Pierre et  Marie Curie" and
`071` = "Mairie  d'Ivry" and line 8 ends with  `080` = "Créteil Pointe
du Lac"). If a station is located on a single line, yet has a corridor
connection  with  another  station  on   another  line,  it  is  still
identified with the line number.  For example, station "Les Halles" is
located on  line 4 and is  connected to station "Châtelet  les Halles"
through a corridor. "Les Halles" is coded `04F`.

![Neighbourhood of 04F, CLH, CHA, 04G, 07L, 07M](RATP-1.png)

In other maps,  the colour is used  to show regions or  big areas. For
the subway  network, there is  neither obvious nor interesting  way to
define regions.  So I used  colours to try representing  subway lines.
The standard RATP  map has a palette with more  than 10 colours, while
my programmes have  only 4 coulours (in addition to  black and white).
So for example  I merged pink (line  7) and purple (line  4) with red.
See  the  picture  above,  with `04E`  (Étienne  Marcel),  `04F`  (Les
Halles), `CHA` (Châtelet),  `04G` (Cité), `07L` (Pont  Neuf) and `07M`
(Pont Marie). Somewhat inconsistently,  I merged lilac-purple (line 8)
with blue. The corridor connections are drawn in black.

![Neighbourhood of "Place de Clichy" and neighbourhood of "Pasteur"](RATP-2.png)

In maps divided  into regions (or big areas), colours  are assigned to
small areas  (`Areas` records)  in a  first step  and to  border links
(`Borders`  records)  in a  second  step.  In  this network  map,  the
opposite is done.  Colours are assigned to `Borders`  records and then
copied to `Areas`  record if some conditions apply. When  a station is
located on  a single line, it  inherits the colour of  this line. Some
stations connect lines with similar colours, such as "Place de Clichy"
connecting line  2 (dark blue)  to line  13 (light blue)  or "Pasteur"
connecting line 6 (light green) to line 12 (dark green). In this case,
the station inherits the colour from the limited palette. If a station
connects lines  with different colours  (in the limited  palette), the
station is  drawn in black. This  is the case with  "Villiers" (blue +
green) and  "Montparnasse-Bienvenüe" (blue  + red  + green).  For this
step, black corridor connections are not considered. See station `04F`
(Les Halles) in the second picture above:  if is drawn in red, even if
it has a black-drawn connection to `CLH` (Châtelet-les-Halles).

Until now, I was working with  plain standard undirected graphs. I did
not use the "multigraph" variant. And I continue avoiding multigraphs.
Yet, there  are cases where multigraphs  seems to be required.  One of
these  cases is  line  8  and line  9  between "Richelieu-Drouot"  and
"République". There  are both a  line 8 segment  and a line  9 segment
from  "Richelieu-Drouot"  to  "Grands  Boulevards",  as  from  "Grands
Boulevards"   to   "Bonne   Nouvelle",  from   "Bonne   Nouvelle"   to
"Strasbourg-Saint-Denis"   and    from   "Strasbourg-Saint-Denis"   to
"République". So  I cut line 9  (yellowish green in the  standard map,
green in the limited palette) at "Richelieu-Drouot" and I restarted it
at "République". Stations "Grands Boulevards" and "Bonne Nouvelle" are
coded `08H` and  `08I` as if they belong only  to line 8 (lilac-purple
on the standard map, blue on the limited palette picture).

![Zoom on the part from Richelieu-Drouot to République](RATP-3.png)

The same happens at other points in the map. For instance, contrary to
what I have written in the previous paragraph, line 9 does not restart
at "République", but at "Oberkampf", because there is already a line 5
edge from "République" to "Oberkampf". In the same way, RER line D has
disappeared  completely, because  its `GNO`  → `CLH`  segment overlaps
with RER line B  and its `CLH` → `GLY` segment  overlaps with RER line
A.

There is a loop  in the western end of line 10 and  another one in the
eastern end of  line 7-bis. These loops are  single-track segments, so
the subways always travel in the same direction. Yet, this is modelled
with undirected edges, irrespective of the traffic direction.

The  original RATP  map  shows  lines in  a  stylised  way, with  many
horizontal,  vertical  and 45-degree  segments.  That  means that  the
locations of  the stations do  not exactly reflect  their geographical
positions. An obvious case if the  "Créteil Pointe du Lac" end of line
8. Moreover,  when I  typed the  data file  describing the  network, I
shifted  some positions  so the  generated picture  would not  include
overlapping  stations. This  is an  additional shift  from the  actual
geographical  positions. Yet,  this map  is declared  as a  scaled map
(`with_scale = 1`), so the picture includes a scale.

To generate a no-overlap picture, you should use the `?w=2000&adj=max`
display parameter.

Todo
====

Here is the  list of to-do items, ordered  by decreasing desirability.
But the  order of  implementation will be  different, because  it will
depend on the ease of programming.

1. Find  a way to  reduce the  combinatory explosion of  map `fr2015`.
Very difficult to implement, unless I get some flash of inspiration.

2. Fix  the computation of  relations between specific  regional paths
and specific  full paths.  Very difficult to  implement, unless  I get
some flash of inspiration.

3. For maps with fewer than 50000 full paths (the parameter value can
be changed), go back to the previous version for the content of field
`path` of view `Full_Paths` (and table `Paths`): the content is the
concatenation of specific regional paths instead of the concatenation
of generic regional paths. A side benefit would be that for these
maps, the contents of table `Path_Relations` would be accurate, even
if not fixed (see previous point). The website will be able to deal
with both full paths with a "specific" `path` column and full paths
with a "generic" `path` column. Somewhat difficult to implement, but
still possible.

4. Upgrade Raku module `GD.pm`, by renaming is `GD.rakumod` and adding
line thicknesses and  text display. This update seems easy,  but I may
be mistaken.

5. Similary, port Perl module `Graph.pm`  to Raku. This task will most
certainly be a lengthy  one, but I do not know  the difficulty. I must
understand some technical peculiarities of `Graph.pm`.

Except that I has just discovered
[two](https://raku.land/zef:antononcube/Graph)
[modules](https://raku.land/zef:titsuki/Algorithm::Kruskal)
written by
[other](https://raku.land/zef:antononcube)
[people](https://raku.land/zef:titsuki)
These modules might fulfill my requirements and they will be ready for
use faster than if  I write my own pure-Raku version.  So I guess that
this point is void now.

License
=======

This  text is  licensed  under  the terms  of  Creative Commons,  with
attribution and share-alike (CC-BY-SA).

