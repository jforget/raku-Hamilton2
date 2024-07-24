#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Initialisation de la carte du métro parisien
#     Initialising the map of Paris subway
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;

my Str $fname    = 'RATP';
my $dbh = DBIish.connect('SQLite', database => dbname());

# No this is not a Bobby Tables problem. All table names are controlled by the programme,
# they do not come from an external source.
for <Maps Areas Borders Paths Path_Relations Exit_Borders Messages> -> $table {
  $dbh.execute("delete from $table where map = 'ratp';");
}

$dbh.execute(q:to/SQL/, 'ratp', "Métro");
insert into Maps (map, name, nb_macro, nb_full, nb_generic, specific_paths, fruitless_reason, with_scale, with_isom, full_diameter, full_radius, macro_diameter, macro_radius)
          values (?  , ?   , 0       , 0      , 0         , 0             , ''              , 1         , 0        , 0            , 0          , 0             , 0);
SQL

my $sto-area = $dbh.prepare(q:to/SQL/);
insert into Areas (map, level, code, name, long, lat, color, upper, nb_macro_paths, nb_macro_paths_1, nb_region_paths, exterior, diameter, radius, full_eccentricity, region_eccentricity)
       values     (?,   ?,     ?,    ?,    ?,    ?,   ?,     ?    , 0,              0,                0,               0       , 0       , 0     , 0                , 0)
SQL

my $sto-border = $dbh.prepare(q:to/SQL/);
insert into Borders (map, level, from_code, to_code, upper_from, upper_to, long, lat, color, fruitless, nb_paths, nb_paths_1, cross_idl)
       values       (?,   ?,     ?,         ?,       ?,          ?,        ?,    ?,   ?    , 0,         0,        0         , 0)
SQL

my $upd-border = $dbh.prepare(q:to/SQL/);
update Borders
set long = ?
  , lat  = ?
where map       = ?
and   level     = 2
and   from_code = ?
and   to_code   = ?
SQL

my $sel-area = $dbh.prepare(q:to/SQL/);
select max(from_code) as code, min(color) as col1, max(color) as col2
from   Small_Borders
where  map = ?
and    color != 'Black'
group by from_code
SQL

my $sto-mesg = $dbh.prepare(q:to/SQL/);
insert into Messages (map, dh, errcode, area, nb, data)
       values        (?,   ?,  ?,       '',   0,  '')
SQL

sub MAIN(Bool :$complet = False) {
  my Str $map-name = 'ratp';

  my Str $region;
  my Str $upper;
  my Str $color;
  my Str $region-color;
  my %borders;
  my %middle;
  my %seen;
  my %trans;
  my @areas;

  # Longitudes
  my Num $lon-Mol =   2.26264.Num;  # 48°50'N  2°15'E Michel-Ange Molitor   https://www.openstreetmap.org/#map=18/48.84501/2.26264
  my Num $lon-Vin =   2.43957.Num;  # 48°50'N  2°26'E chateau de Vincennes  https://www.openstreetmap.org/#map=18/48.84452/2.43957
  my Num $x-Mol   =  333.Num;
  my Num $x-Vin   = 2609.Num;
  my Num $a-lon   = ($lon-Vin - $lon-Mol) / ($x-Vin - $x-Mol);
  my Num $b-lon   = $lon-Mol - $a-lon × $x-Mol;
  sub conv-lon(Num $x --> Num) { return $a-lon × $x + $b-lon }

  # Latitudes
  my Num $lat-Uni =  48.82061.Num;  # 48°50'N 2°20'E Cité Universitaire     https://www.openstreetmap.org/#map=18/48.82061/2.33931
  my Num $lat-Cli =  48.89733.Num;  # 48°53'N 2°22'E Porte de Clignancourt  https://www.openstreetmap.org/#map=19/48.89733/2.34508
  my Num $y-Uni   = 2346.Num;
  my Num $y-Cli   =  540.Num;
  my Num $a-lat   = ($lat-Cli - $lat-Uni) / ($y-Cli - $y-Uni);
  my Num $b-lat   = $lat-Uni - $a-lat × $y-Uni;
  sub conv-lat(Num $y --> Num) { return $a-lat × $y + $b-lat }

  my $fh = $fname.IO.open(:r);
  for $fh.lines -> Str $line {
    next if $line ~~ /^ \s* $/;
    next if $line ~~ /^ '#' /;
    my ($lvl, $code, $name, $color-or-long, $latx, $borders) = $line.split(/ \s* ';' \s*/);
    given $lvl {
      when 'A' {
        $region       = $code;
        $region-color = $color-or-long;
        $sto-area.execute($map-name, 1, $code, $name, 0, 0, $region-color, '');
      }
      when 'B' {
        my Num $lon = conv-lon($color-or-long.Num);
        my Num $lat = conv-lat($latx.Num);
        %seen{$name} = 1;
        $sto-area.execute($map-name, 2, $code, $name, $lon, $lat, 'Black', $region);
        push @areas, $code;
      }
      when 'L' {
        my $color = $code;
        my @stations = $name.uc.split(/',' \s*/);
        my $st1 = @stations.shift;
        for @stations -> $st2 {
          $sto-border.execute($map-name, 2, $st1, $st2, $region, $region, 0, 0, $color);
          $sto-border.execute($map-name, 2, $st2, $st1, $region, $region, 0, 0, $color);
          $st1 = $st2;
        }
      }
      when 'X' {
        my Num $lon = conv-lon($color-or-long.Num);
        my Num $lat = conv-lat($latx.Num);
        %middle{$code}{$name}<lon> = $lon;
        %middle{$code}{$name}<lat> = $lat;
        %middle{$name}{$code}<lon> = $lon;
        %middle{$name}{$code}<lat> = $lat;
        $upd-border.execute($lon, $lat, $map-name, $code, $name);
        $upd-border.execute($lon, $lat, $map-name, $name, $code);
      }
    }
  }
  $fh.close;

  # Longitude and latitude in the big area are computed with the average of lon/lat for nodes
  $dbh.execute(q:to/SQL/, $map-name);
  update Areas
  set (long, lat) = (select avg(Small_Areas.long), avg(Small_Areas.lat)
                     from   Small_Areas
                     where  Small_Areas.map   = Areas.map
                       and  Small_Areas.upper = Areas.code)
  where map   = ?
    and level = 1
  SQL

  my @colors = $sel-area.execute($map-name).allrows(:array-of-hash);
  for @colors -> $elem {
    if $elem<col1> eq $elem<col2> {
      $dbh.execute(q:to/SQL/, $elem<col1>, $map-name, $elem<code>)
      update  Areas
      set     color = ?
      where   map   = ?
      and     level = 2
      and     code  = ?
      SQL
    }
  }

  $sto-mesg.execute($map-name, DateTime.now.Str, 'INIT');
}

=begin POD

=encoding utf8

=head1 NAME

init-ratp.raku -- initialising the graph for the Paris subway network

=head1 DESCRIPTION

This programme  reads a file  listing all  stations and lines  for the
Paris subway  network and  store them in  the database.  Tables filled
are: C<Maps>, C<Regions> and C<Borders>.

=head1 USAGE

  sqlite3 Hamilton.db < cr.sql
  raku init-ratp.raku

=head2 Parameters

None.

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<init-ratp.raku> program.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2024 Jean Forget, all rights reserved

This  program is  published under  the  same conditions  as Raku:  the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
