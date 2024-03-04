#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Export de graphes vers Graphiviz / neato and Tulip
#     Exporting graphs for Graphiviz / neato and Tulip
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

my $sth-all-areas = $dbh.prepare(q:to/SQL/);
select  *
from    Areas
where   map   = ?
and     level = ?
SQL

my $sth-some-areas = $dbh.prepare(q:to/SQL/);
select  *
from    Areas
where   map   = ?
and     level = 2
and     upper = ?
SQL

my $sth-some-borders = $dbh.prepare(q:to/SQL/);
select  *
from    Borders
where   map   = ?
and     level = 2
and     upper_from = ?
and     upper_to   = upper_from
and     from_code  < to_code
SQL

my $sth-all-borders = $dbh.prepare(q:to/SQL/);
select  *
from    Borders
where   map   = ?
and     level = ?
and     from_code  < to_code
SQL

my $sth-neighbours = $dbh.prepare(q:to/SQL/);
select to_code
from   Borders
where  map       = ?
  and  level     = ?
  and  upper_to  = ?
  and  from_code = ?
SQL

sub MAIN (
      Str  :$map                   #= The code of the map
    , Bool :$macro       = False   #= True to export the macro-map, else False
    , Bool :$full        = False   #= True to export the full map, else False
    , Bool :$all-regions = False   #= True to export all regional maps, else False
    , Str  :$regions = ''          #= Comma-delimited list of region codes, e.g. --regions=NOR,CEN,HDF
    , Str  :$dir='.'               #= directory where the output files are written
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

  if $macro {
    say "exporting macro-map for $map";
    export($map, 1, '', "$dir/map-{$map}-macro.dot");
  }
  if $full {
    say "exporting full map for $map";
    export($map, 2, '', "$dir/map-{$map}-full.dot");
  }
  if $all-regions {
    say "exporting regional maps for all regions of $map";
    for access-sql::list-big-areas($map) -> $region {
      my $code = $region<code>;
      say "exporting regional map for region $code of $map";
      export($map, 2, $code, "$dir/map-{$map}-$code.dot");
    }
  }
  if $regions ne '' {
    for @regions -> Str $region {
      my $code = $region<code>;
      say "exporting regional map for region $code of $map";
      export($map, 2, $code, "$dir/map-{$map}-$code.dot");
    }
  }
}

sub export($map, $level, $region, $fname) {
  my $fh = open $fname, :w;
  $fh.print(q:to/EOF/);
  graph map {
  EOF

  my @areas;
  my @borders;
  if $region eq '' {
    @areas   = $sth-all-areas  .execute($map, $level).allrows(:array-of-hash);
    @borders = $sth-all-borders.execute($map, $level).allrows(:array-of-hash);
  }
  else {
    @areas   = $sth-some-areas  .execute($map, $region).allrows(:array-of-hash);
    @borders = $sth-some-borders.execute($map, $region).allrows(:array-of-hash);
  }
  for @areas -> $area {
    $fh.printf("  %s [color=%s, pos=\"%f,%f\"]\n", $area<code>, $area<color>, $area<long>, $area<lat>);
  }
  for @borders -> $border {
    $fh.printf("  %s -- %s [color=%s]\n", $border<from_code>, $border<to_code>, $border<color>);
  }

  $fh.print("}\n");
  $fh.close;
}

=begin POD

=encoding utf8

=head1 NAME

export.raku -- exporting full maps, macro-maps and regional maps to Graphviz

=head1 DESCRIPTION

This programme  generates I<xxx>C<.dot> files for a map.

=head1 SYNOPSIS

  raku export.raku --map=frreg --full --macro --regions=NOR,HDF --dir=$HOME/graphs
  neato -Tpng -O $HOME/graphs/map-frreg-NOR.dot
  tulip $HOME/graphs/map-frreg-macro.dot

=head1 PARAMETERS

=head2 map

The code of the map, e.g. C<fr1970> or C<frreg>.

=head2 macro

Boolean parameter to run or to bypass macro-map generation.

=head2 full

Boolean parameter to run or to bypass full map generation.

=head2 all-regions

Boolean parameter to run or to bypass regional map generation for all regions.

=head2 regions

If parameter C<all-regions> is not set, this parameter gives the codes
of the regions that will be  processed. The region codes are separated
by commas (with no spaces).

=head2 dir

Name of the directory where the output files will be stored.

=head1 OTHER ELEMENTS

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<gener1.raku> programme.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2024 Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
