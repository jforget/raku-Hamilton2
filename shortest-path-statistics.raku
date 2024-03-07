#!/usr/bin/env raku
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Calcul des statistiques associées aux "plus courts chemins" : excentricité des sommets dans les graphes, diamètre et rayon d'un graphe
#     Computing the  statistics associated with "shortest paths": eccentricity of nodes in graphs, diameter and radius of a graph
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;
use access-sql;
use Graph:from<Perl5>;

my $dbh = DBIish.connect('SQLite', database => dbname());

my $upd-map-diameter = $dbh.prepare(q:to/SQL/);
update Maps
set    macro_diameter = ?
  ,    macro_radius   = ?
  ,    full_diameter  = ?
  ,    full_radius    = ?
where  map = ?
SQL

my $upd-region-diameter = $dbh.prepare(q:to/SQL/);
update Areas
set    diameter = ?
  ,    radius   = ?
where  map   = ?
and    level = 1
and    code  = ?
SQL

my $upd-full-eccentricity = $dbh.prepare(q:to/SQL/);
update Areas
set    full_eccentricity = ?
where  map   = ?
and    level = ?
and    code  = ?
SQL

my $upd-region-eccentricity = $dbh.prepare(q:to/SQL/);
update Areas
set    region_eccentricity = ?
where  map   = ?
and    level = 2
and    code  = ?
SQL

my $sto-mesg = $dbh.prepare(q:to/SQL/);
insert into Messages (map, dh, errcode, area, nb, data)
       values        (?,   ?,  ?,       ?,    ?,  ?)
SQL

sub MAIN (
      Str  :$map #= The code of the map
    ) {

  my %map = access-sql::read-map(~ $map);
  unless %map {
    die "Unkown map $map";
  }
  $dbh.execute("begin transaction");
  $sto-mesg.execute($map, DateTime.now.Str, 'STA1', '', 0, '');
  my Int ($d1, $d2, $r1, $r2);
  my @regions = access-sql::list-big-areas($map);
  ($d1, $r1) = compute-metrics($map, 1, '', @regions, access-sql::list-big-borders($map));
  ($d2, $r2) = compute-metrics($map, 2, '', access-sql::list-small-areas($map), access-sql::list-small-borders($map));
  $upd-map-diameter.execute($d1, $r1, $d2, $r2, $map);
  for @regions -> $region {
    my Str $reg = $region<code>;
    ($d2, $r2) = compute-metrics($map, 2, $reg, access-sql::list-areas-in-region($map, $reg), access-sql::list-borders-in-region($map, $reg));
    $upd-region-diameter.execute($d2, $r2, $map, $reg);
  }
  $sto-mesg.execute($map, DateTime.now.Str, 'STA2', '', 0, '');
  $dbh.execute("commit");

}

sub compute-metrics(Str $map, Int $level, Str $region, @areas, @borders) {
  if @areas.elems ≤ 1 {
    return (0, 0);
  }
  my @area-codes = @areas.map( { $_<code> } );
  my @border-codes = ();
  for @borders -> $border {
    if $border<code_f> lt $border<code_t> {
      @border-codes.push([$border<code_f>, $border<code_t>]);
    }
  }
  my $graph = Graph.new(undirected => 1
                      , vertices   => @area-codes
                      , edges      => @border-codes);
  unless $graph.is_connected {
    for @area-codes -> Str $code {
      if $region eq '' {
        $upd-full-eccentricity.execute(-1, $map, $level, $code);
      }
      else {
        $upd-region-eccentricity.execute(-1, $map, $code);
      }
    }
    return (-1, -1);
  }
  my Int $diameter = -1 + $graph.diameter;
  my Int $radius   = $graph.radius.Int;
  my @nodes-per-ecc;
  for 0..^ 0 + $graph.diameter() -> $i {
    @nodes-per-ecc[$i] = [ ];
  }
  for @area-codes -> Str $code {
    my Int $ecc = $graph.vertex_eccentricity($code);
    if $region eq '' {
      $upd-full-eccentricity.execute($ecc, $map, $level, $code);
    }
    else {
      $upd-region-eccentricity.execute($ecc, $map, $code);
    }
  }
  return ($diameter, $radius);
}

=begin POD

=encoding utf8

=head1 NAME

shortest-path-statistics.raku -- computing the "shortest paths" statistics for a map

=head1 DESCRIPTION

This  programme generates  compute the  metrics statistics  for a  map
associated with shortest paths:  diameter, radius, eccentricity of all
nodes. These metrics are computed for  the full map, for the macro-map
and for each region map.

=head1 USAGE

  raku shortest-path-statistics.raku --map=frreg

=head1 PARAMETER

=head2 map

The code of the map, e.g. C<fr1970> or C<frreg>.

=head1 OTHER ELEMENTS

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<gener1.raku> programme.

=head1 PROBLEMS AND KNOWN BUGS

It seems that the definition of a diameter is different between module
C<Graph.pm> used  by this  programme and other  documentation sources.
C<Graph.pm> counts  the nodes  in the  "longest shortest  path", other
sources count the edges. For example,  the diameter of a star graph Sn
or a wheel graph Wn (n ≥ 5) is 3 when computed by C<Graph.pm>, it is 2
when computed according to other  sources. In this programme, we adopt
the edge-counting definition.

Also, it seems that the diameter and  the radius are not defined for a
graph with only one node. I think these values could be defined with a
value zero in this case, which is a consistent extension to the values
for connected graphs with at least one edge.

On  the other  hand,  the  eccentriciy, diameter  and  radius are  not
defined  for  unconnected  graphs.  In  the  database,  they  have  an
out-of-bounds value -1.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2024 Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
