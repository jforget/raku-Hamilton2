#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération des macro-chemins hamiltoniens et des chemins hamiltoniens régionaux
#     Generating macro-paths and regional paths
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;
use access-sql;

my $dbh = DBIish.connect('SQLite', database => dbname());

my $sto-mesg = $dbh.prepare(q:to/SQL/);
insert into Messages (map, dh, errcode, area, nb, data)
       values        (?,   ?,  ?,       ?,    ?,  ?)
SQL

my $sto-path = $dbh.prepare(q:to/SQL/);
insert into Paths (map, level, area, num, path, from_code, to_code, cyclic, macro_num, fruitless, fruitless_reason, nb_full_paths, generic_num, first_num, paths_nb, num_s2g)
       values     (?,   ?,     ?,    ?,   ?,    ?,         ?,       ?,      0,         0,         '',               0,             0,           ?,         ?,        0)
SQL

my $sth-neighbours = $dbh.prepare(q:to/SQL/);
select to_code
from   Borders
where  map       = ?
  and  level     = ?
  and  upper_to  = ?
  and  from_code = ?
SQL

my $sth-check-cyclic = $dbh.prepare(q:to/SQL/);
select 'X'
from   Borders
where  map       = ?
  and  level     = ?
  and  from_code = ?
  and  to_code   = ?
SQL

my $upd-stat-big-a = $dbh.prepare(q:to/SQL/);
update Areas as A
set nb_macro_paths = (select count(*)
                      from   Paths as P
                      where  P.map   = A.map
                      and    P.level = 1
                      and    A.code  in (P.from_code, P.to_code)
                      )
where  map   = ?
and    level = 1
SQL

my $upd-stat-small-a = $dbh.prepare(q:to/SQL/);
update Areas as A
set nb_region_paths = (select count(*)
                       from   Paths as P
                       where  P.map   = A.map
                       and    P.level = 2
                       and    P.area  = A.upper
                       and    A.code  in (P.from_code, P.to_code)
                       )
where  map   = ?
and    level = 2
and    upper = ?
SQL

my $upd-stat-big-b = $dbh.prepare(q:to/SQL/);
update Borders as B
set nb_paths = 2 * (select count(*)
                    from   Paths as P
                    where  P.map   = B.map
                    and    P.level = 1
                    and    P.path  like '%' || B.from_code || ' → ' || B.to_code   || '%'
                    )
where  map        = ?
and    level      = 1
SQL

my $upd-stat-small-b = $dbh.prepare(q:to/SQL/);
update Borders as B
set nb_paths = 2 * (select count(*)
                    from   Paths as P
                    where  P.map   = B.map
                    and    P.level = 2
                    and    P.path  like '%' || B.from_code || ' → ' || B.to_code   || '%'
                    )
where  map        = ?
and    level      = 2
and    upper_from = ?
and    upper_to   = upper_from
SQL

sub MAIN (
      Str  :$map             #= The code of the map
    , Bool :$macro = False   #= True to generate the macro-paths, else False
    , Str  :$regions = ''    #= Comma-delimited list of region codes, e.g. --regions=NOR,CEN,HDF
    ) {

  my %map = access-sql::read-map(~ $map);
  unless %map {
    die "Unkown map $map";
  }

  my Str @regions = $regions.split(',');
  my Str @unknown-regions;
  if $regions ne '' {
    for @regions -> Str $region {
      my $result = $dbh.execute("select 'X' from Big_Areas where map = ? and code = ?", $map, $region).row;
      if $result ne 'X' {
        push @unknown-regions, $region;
      }
    }
  }
  if @unknown-regions {
    die "Unknown regions: ", @unknown-regions.join(', ');
  }

  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths          where map = ? and level = 3", $map);
  $dbh.execute("delete from Path_Relations where map = ?"              , $map);
  $dbh.execute("commit");

  if $macro or $regions eq '' {
    say "generating macro-paths for $map";
    my $nb = generate($map, 1, '', 'MAC');
    $dbh.execute("begin transaction");
    $dbh.execute("update Maps set nb_macro = ? where map = ?", $nb, $map);
    $upd-stat-big-a.execute($map);
    $upd-stat-big-b.execute($map);
    $dbh.execute("commit");
  }
  if ! $macro && $regions eq '' {
    say "generating regional paths for all regions of $map";
    for access-sql::list-big-areas($map) -> $region {
      say "generating regional paths for region $region<code> of $map";
      my $nb = generate($map, 2, $region<code>, 'REG');
      $dbh.execute("begin transaction");
      $dbh.execute("update Areas set nb_region_paths = ? where map = ? and level = 1 and code = ?", + $nb, $map, $region<code>);
      $upd-stat-small-a.execute($map, $region<code>);
      $upd-stat-small-b.execute($map, $region<code>);
      $dbh.execute("commit");
      generic-paths($map, $region<code>);
    }
  }
  if $regions ne '' {
    for @regions -> Str $region {
      say "generating regional paths for region $region of $map";
      my $nb = generate($map, 2, $region, 'REG');
      $dbh.execute("begin transaction");
      $dbh.execute("update Areas set nb_region_paths = ? where map = ? and level = 1 and code = ?", $nb, $map, $region);
      $upd-stat-small-a.execute($map, $region);
      $upd-stat-small-b.execute($map, $region);
      $dbh.execute("commit");
      generic-paths($map, $region<code>);
    }
  }
}

sub generate(Str $map, Int $level, Str $region, Str $prefix --> Int) {

  # Initial clean-up for the region
  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths    where map = ? and level = ? and area = ?", $map, $level, $region);
  $dbh.execute("delete from Messages where map = ? and area = ? and errcode like ?", $map, $region, $prefix ~ '%');
  $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '1', $region, 0, '');
  $dbh.execute("commit");

  # For each small area, counting how many borders this area shares with other small areas from the same big area.
  # For each big area, just count how many borders.
  my @all-areas;
  my @dead-end-areas;
  my @isolated-areas;
  my $sth = $dbh.prepare(q:to/SQL/);
  select A.code, count(B.from_code) cnt
  from      Areas   A
  left join Borders B
    on   B.map        = A.map
    and  B.level      = A.level
    and  B.from_code  = A.code
    and  B.upper_to   = A.upper
  where  A.map   = ?
  and    A.level = ?
  and    A.upper = ?
  group by A.map, A.level, A.code
  order by A.map, A.level, A.code
  SQL
  for $sth.execute($map, $level, $region).allrows(:array-of-hash) -> $row {
    #say $row;
    push @all-areas     , $row<code>;
    push @dead-end-areas, $row<code> if $row<cnt> == 1;
    push @isolated-areas, $row<code> if $row<cnt> == 0;
  }

  if @isolated-areas.elems == 1 && @all-areas.elems == 1 {
    # easy generation: just one path of length zero!
    my Str $single-area = @isolated-areas[0];
    #say "region $region has only one area, only one path and its length is zero";
    $dbh.execute("begin transaction");
    $sto-path.execute($map, $level, $region, 1, $single-area, $single-area, $single-area, 1, 0, 0);
    $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '2', $region, 1, '');
    $dbh.execute("commit");
    return 1;
  }

  if @isolated-areas.elems ≥ 1 && @all-areas.elems > 1 {
    #say "region $region is not connected: {@isolated-areas}";
    $dbh.execute("begin transaction");
    $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '3', $region, 0, @isolated-areas.join(' '));
    $dbh.execute("commit");
    return 0;
  }

  if @dead-end-areas.elems ≥ 3 {
    #say "region $region has too many dead ends: {@dead-end-areas}";
    $dbh.execute("begin transaction");
    $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '4', $region, 0, @dead-end-areas.join(' '));
    $dbh.execute("commit");
    return 0;
  }

  my @to-do-list;
  my Bool $there-and-back-again = False;
  if @dead-end-areas.elems ≥ 1 {
    my Str $dead-end = @dead-end-areas[0];
    #say "region $region uses dead-end $dead-end";
    $there-and-back-again = True;
    push @to-do-list, {  path => $dead-end
                       , from => $dead-end
                       , to   => $dead-end
                       , free => set(|@all-areas) (-) set($dead-end) };
    $dbh.execute("begin transaction");
    $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '5', $region, 0, $dead-end);
    $dbh.execute("commit");
  }
  else {
    #say "region $region: complete generation";
    for @all-areas -> $r {
      push @to-do-list, {  path => $r
                         , from => $r
                         , to   => $r
                         , free => set(|@all-areas) (-) set($r) };
    }
  }

  my Int $path-number = 0;
  my Int $partial-paths-nb   = @to-do-list.elems;
  my Int $max-to-do          = @to-do-list.elems;
  my Int $complete-threshold =     0;
  my Int $complete-increment = commit-interval();
  my Int $partial-threshold  =     0;
  my Int $partial-increment  = 10000;

  my %neighbours;
  for @all-areas -> $area {
    my @nei = $sth-neighbours.execute($map, $level, $region, $area).allrows.map( { $_[0] } );
    %neighbours{$area} = @nei;
  }

  sub aff-stat {
    say "{DateTime.now.hh-mm-ss} complete paths $path-number, partial paths $partial-paths-nb (to-do list {@to-do-list.elems} / $max-to-do)";
  }
  $dbh.execute("begin transaction");

  while @to-do-list.elems ≥ 1 {
    if $max-to-do < @to-do-list.elems {
      $max-to-do = @to-do-list.elems
    }
    my $partial-path = @to-do-list.pop;
    for %neighbours{$partial-path<to>}.List -> $next {
      #say $partial-path<to>, " → ", $next, ' ', $partial-path<free>, ' ', $partial-path<free>{$next};
      if $partial-path<free>{$next} {
        my Str $new-path = "{$partial-path<path>} → $next";
        my Set $new-free = $partial-path<free> (-) set($next);
        if $new-free.elems == 0 {
          ++ $path-number;

          my $result = $sth-check-cyclic.execute($map, $level, $partial-path<from>, $next).row;
          my Int $cyclic;
          if $result eq 'X' {
            $cyclic = 1;
          }
          else {
            $cyclic = 0;
          }

          $sto-path.execute($map, $level, $region, $path-number, $new-path, $partial-path<from>, $next, $cyclic, 0, 0);
          if $there-and-back-again {
            my Str $rev-path = $new-path.split(/ \s* '→' \s* /).reverse.join(" → ");
            ++ $path-number;
            $sto-path.execute($map, $level, $region, $path-number, $rev-path, $next, $partial-path<from>, $cyclic, 0, 0);
          }
          if $path-number ≥ $complete-threshold {
            $dbh.execute("commit");
            $dbh.execute("begin transaction");
            aff-stat();
            $complete-threshold += $complete-increment;
          }
        }
        else {
          push @to-do-list, {  path => $new-path
                             , from => $partial-path<from>
                             , to   => $next
                             , free => $new-free };
          ++$partial-paths-nb;
          if $partial-paths-nb ≥ $partial-threshold {
            aff-stat();
            $partial-threshold += $partial-increment;
          }
        }
      }
    }
  }
  $dbh.execute("commit");
  aff-stat();

  $dbh.execute("begin transaction");
  if $path-number != 0 {
    $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '7', $region, $path-number, '');
  }
  else {
    $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '6', $region, $path-number, '');
  }
  $dbh.execute("commit");

  # reordering the paths
  if $path-number != 0 {
    $dbh.execute("begin transaction");

    my $sth-sel = $dbh.prepare(q:to/SQL/);
    select path
    from Paths
    where map   = ?
    and   level = ?
    and   area  = ?
    order by from_code, to_code, path
    SQL

    my $sth-upd = $dbh.prepare(q:to/SQL/);
    update Paths
    set   num = ?
    where map   = ?
    and   level = ?
    and   area  = ?
    and   path  = ?
    SQL

    my Int $n = 0;
    for $sth-sel.execute($map, $level, $region).allrows(:array-of-hash) -> $row {
      $n++;
      $sth-upd.execute($n, $map, $level, $region, $row<path>);
      if $n %% $complete-increment {
        $dbh.execute("commit");
        $dbh.execute("begin transaction");
        say "{DateTime.now.hh-mm-ss} renumbering path $n / $path-number";
      }
    }
    $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '8', $region, $path-number, '');
    $dbh.execute("commit");
  }
  return $path-number;
}

sub generic-paths(Str $map, Str $region) {
  my Str $prefix = 'REG';
  my Int $path-number  = 0;
  my Int $first-number = 1;

  say "{DateTime.now.hh-mm-ss} computing generic regional paths for region $region of $map";
  $dbh.execute("begin transaction");
  $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '9', $region, 0, '');
  $dbh.execute("delete from Paths where map = ? and level = 4 and area = ?", $map, $region);

  my $sth-sel = $dbh.prepare(q:to/SQL/);
  select from_code as from_code, to_code as to_code, count(*) as nb
  from Region_Paths
  where map  = ?
    and area = ?
  group by from_code, to_code
  order by from_code, to_code
  SQL

  my $sth-upd = $dbh.prepare(q:to/SQL/);
  update Paths
  set generic_num = ?
    , num_s2g     = num - ?
  where map       = ?
    and level     = 2
    and area      = ?
    and from_code = ?
    and to_code   = ?
  SQL

  for $sth-sel.execute($map, $region).allrows(:array-of-hash) -> $row {
    $path-number++;
    $sto-path.execute($map, 4, $region, $path-number, "($region,$first-number,$row<nb>)", $row<from_code>, $row<to_code>, 0, $first-number, $row<nb>);
    $sth-upd.execute($path-number, $first-number, $map, $region, $row<from_code>, $row<to_code>);
    $first-number += $row<nb>
  }

  $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ 'A', $region, $path-number, '');
  $dbh.execute("commit");
}

=begin POD

=encoding utf8

=head1 NAME

gener1.raku -- generating the macro-paths and regional paths for a region

=head1 DESCRIPTION

This programme  generates some or  all macro-paths and  regional paths
for a map.

=head1 USAGE

  raku gener1.raku --map=frreg --macro --regions=NOR,HDF

=head1 PARAMETERS

=head2 map

The code of the map, e.g. C<fr1970> or C<frreg>.

=head2 macro

Boolean parameter to run or to bypass macro-path generation.

=head2 regions

String giving the codes of the regions that will be processed.
The region codes are separated by commas (with no spaces).

=head2 Special case

If both C<macro> and C<regions> parameters are missing (or C<False> in
the case  of C<macro>),  then the  generation programme  generates all
macro-paths and all regional paths for all regions of the map.

On the other hand, the C<map> parameter is mandatory.

=head2 Parameter Summary

If you want to generate only macro-paths without any regional paths:

  raku gener1.raku --map=frreg --macro

If you want to generate macro-paths and some regional paths

  raku gener1.raku --map=frreg --macro --regions=NOR,HDF

If you want to generate macro-paths and regional paths for all regions

  raku gener1.raku --map=frreg

If you want to generate neither macro-paths nor regional paths.

Why  would you  do that?  You  just type  nothing. You  do not  launch
C<gener1.raku>.

If you want to generate some regional paths but no macro-paths

  raku gener1.raku --map=frreg --regions=NOR,HDF

If you want to generate regional paths for all regions, but no macro-paths.

Sorry, that is not possible.

=head1 OTHER ELEMENTS

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<gener1.raku> programme.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2022, 2023, 2024 Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
