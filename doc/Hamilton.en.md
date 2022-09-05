-*- encoding: utf-8; indent-tabs-mode: nil -*-

This  project  aims  at   extracting  doubly  hamiltonian  paths  from
administrative maps. In a connected graph, an
[Hamiltonian path](https://mathworld.wolfram.com/HamiltonianPath.html)
is a  path crossing each vertex  exactly once. But what  is a _doubly_
Hamiltonian path?  Let us consider  the administrative map  of France.
France  is  split  into  _régions_,  which  are  in  turn  split  into
_départements_. For the purpose of  this project, we put aside Corsica
and overseas  regions, so the  resulting graph is connected.  A doubly
Hamiltonian path  is an hamiltonian path  crossing each one of  the 94
departments, with  the additional  constraint that when  narrowing the
view on any single region, the partial path is still Hamiltonian.

Checking whether  an Eulerian path  exists in  a connected graph  is a
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
[Maharadjah](https://boardgamegeek.com/image/82336/maharaja).

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

The  first  table  is  the  `Maps` table.  It  just  contains  a  code
(URL-friendly, no special characters) and a description. It is used in
the website's main page, so the user can choose which map to display.

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
similar to the code for the 2015-variant regions.

Other fields are:

* `name` the standard designation of the region / department,
* `long` and `lat`, approximate longitude and latitude of the area,
* `color` the color used when drawing the map,
* `upper` for departments, it is the code of the region it belongs to, for regions this field is unused.

Two view are defined on  this table, `Big_Areas` which filters `level`
equal  to `1`  for regions  and  `Small_Areas` which  filters `2`  for
departments.

The longitude and latitude will be used to draw the maps. Although the
current problem of Hamiltonian paths is strictly a math graph problem,
with no geometry  involved, the math graphs will be  displayed in such
fashion that  the geographical  map associated can  be guessed  at and
recognised.

Borders
-------

The `Borders` table  lists the pairs of neighbour  departments and the
pairs of neighbour regions. For a math graph, the proper word would be
"edges". The key contains:

* `map` the key from table `Maps`,
* `level` with `1` for neighbouring regions and `2` for neighbouring departments,
* `from_code` for the first area,
* `to_code` for the second ares.

Other fields:

* `upper_from` the code of the region for departments' edges, empty for regions' edges,
* `upper_to` similar,
* `long`
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
departments belonging to separate regions,  the color will be `Black`.
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
* `macro_num` the number of the associated macro path, if there is one.

The `path`  field contains the  department codes (or region  codes for
macro-paths)  separated   by  arrows  `→`.   In  the  1970   map,  the
_Languedoc-Roussillon_ region has  two regional paths. Here  is one of
them:

```
   map         "fr1970"
   level       2
   area        "LRO"
   num         1
   path        "48 → 30 → 34 → 11 → 66"
   from_code   48
   to_code     66
   macro_num   0
```

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

Initialisation
==============

For copyright  reasons, I  will not provide  initialisation programmes
for  the  maps of  Risk,  War  on Terror  and  other  games. The  only
initialisation  programme will  be the  programme dealing  with French
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
file. Also, I have listed all neighbouring departments. In some cases,
I have  zoomed to know if  two departments are really  neighbours. See
for example  the 4-way  point between Vaucluse,  Bouches-du-Rhône, Var
and Alpes  de Haute-Provence. Back  to long/lat: I  have copied-pasted
the values with all 5 digits after the decimal point. If you bother to
check,  one  latitude degree  is  111  km  and,  at latitude  45,  one
longitude degree is  78 km. So the fifth decimal  digit means that the
values have a precision of one meter, more or less. This is excessive.
I could have truncated to 2 decimal digits.

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
records.  For  each  region,  the   programme  will  extract  all  the
departments within this  region, compute the average  of the latitudes
and longitudes of these departments  and update the region record with
these computed values.

Likewise, the  programme will create  the `Borders` records  with keys
`fr1970`+`1`, `fr2015`+`1`  `frreg`+`1` and `frreg`+`2`  by extracting
all departments  borders `fr1970`+`2`  and `fr2015`+`2`  lying between
two different regions, discarding all duplicates region-wise and store
the result in the `Borders` table.

Extracting Hamiltonian Paths
============================

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

License
=======

This  text is  licensed  under  the terms  of  Creative Commons,  with
attribution and share-alike (CC-BY-SA).

