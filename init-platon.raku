#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Initialisation des graphes correspondant aux solides platoniciens
#     Initialising the graphs associated with platonic solids
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;

sub MAIN (
      Str  :$fname = 'platonic.txt' #= The path of the file containing the graph descriptions
    ) {

  my $dbh = DBIish.connect('SQLite', database => dbname());
  my Num $ε = 1e-8;

  my $sto-map = $dbh.prepare(q:to/SQL/);
  insert into Maps (map, name, nb_macro, nb_full, nb_generic, specific_paths, fruitless_reason, with_scale, with_isom, full_diameter, full_radius, macro_diameter, macro_radius)
         values    (?,   ?,    0,        0,       0,          0             , '',               0         , 0        , 0            , 0          , 0             , 0);
  SQL

  my $sto-area = $dbh.prepare(q:to/SQL/);
  insert into Areas (map, level, code, name, long, lat, color, upper, nb_macro_paths, nb_macro_paths_1, nb_region_paths, exterior, diameter, radius, full_eccentricity, region_eccentricity)
         values     (?,   ?,     ?,    ?,    ?,    ?,   ?,     ?    , 0,              0,                0,               0       , 0       , 0     , 0                , 0)
  SQL

  my $sto-border = $dbh.prepare(q:to/SQL/);
  insert into Borders (map, level, from_code, to_code, upper_from, upper_to, long, lat, color, fruitless, nb_paths, nb_paths_1, cross_idl)
         values       (?,   ?,     ?,         ?,       ?,          ?,        ?,    ?,   ?    , 0,         0,        0         , 0)
  SQL

  my $sto-mesg = $dbh.prepare(q:to/SQL/);
  insert into Messages (map, dh, errcode, area, nb, data)
         values        (?,   ?,  ?,       '',   0,  '')
  SQL

  my $upd-area = $dbh.prepare(q:to/SQL/);
  update Areas
  set (long, lat) = (select avg(Small_Areas.long), avg(Small_Areas.lat)
                     from   Small_Areas
                     where  Small_Areas.map   = Areas.map
                       and  Small_Areas.upper = Areas.code)
  where map   = ?
    and level = 1
  SQL

  my     @maps = ();
  my Str $map;
  my Str $region;
  my Str $colour;
  my     %borders;
  my     %middle;

  my $fh = $fname.IO.open(:r);
  for $fh.lines -> Str $line {
    my ($lvl, $code, $name, $color-or-coord, $borders) = $line.split(/ \s* ';' \s*/);
    $color-or-coord //= '';
    given $lvl {
      when 'A' {

        $map = ~ $code;
        @maps.push($map);

        # No this is not a Bobby Tables problem. All table names are controlled by the programme,
        # they do not come from an external source.
        for <Maps Areas Borders Paths Path_Relations Exit_Borders Isometries Isom_Path Messages> -> $table {
          $dbh.execute("delete from $table where map = ?;", $map);
        }
        $sto-map.execute($map, $name);
        $region = ~ $code;
        $colour = ~ $color-or-coord;
        $sto-area.execute($code, 1, $region, $name, 0, 0, $colour, '');
      }
      when 'B' {
        my ($long1, $lat1) = $color-or-coord.split(/ \s* ',' \s* /);

        # + 1e-8 so that SQLite will store this as a float, not an int.
        my Num $long = $long1 + $ε;
        my Num $lat  = $lat1  + $ε;

        $sto-area.execute($map , 2, $code, $name, $long, $lat, $colour, $region);

        for $borders.split(/ \s* ',' \s*/) -> $neighbour {
          %borders{$map}{$code}{$neighbour}<counter>++;
          %borders{$map}{$code}{$neighbour}<from>   = $region;
          %borders{$map}{$code}{$neighbour}<colour> = $colour;

          %borders{$map}{$neighbour}{$code}<counter>++;
          %borders{$map}{$neighbour}{$code}<to> = $region;
        }
      }
      when 'X' {
        my ($lonx, $latx) = $color-or-coord.split(/ \s* ',' \s* /);
        my Num $lon = $lonx.Num + $ε;
        my Num $lat = $latx.Num + $ε;
        %middle{$map}{$code}{$name}<lon> = $lon;
        %middle{$map}{$code}{$name}<lat> = $lat;
        %middle{$map}{$name}{$code}<lon> = $lon;
        %middle{$map}{$name}{$code}<lat> = $lat;
      }
    }
  }
  $fh.close;

  for @maps -> Str $map {
    $upd-area.execute($map);

    for %borders{$map}.kv -> $from, $hashto {
      for %$hashto.kv -> $to, $border {
        if $border<counter> != 2 {
          say "problem with $from → $to";
        }
        elsif $from le $to {
          my Num $lon   = 0e0;
          my Num $lat   = 0e0;
          if %middle{$map}{$from}{$to} {
            $lon = %middle{$map}{$from}{$to}<lon>;
            $lat = %middle{$map}{$from}{$to}<lat>;
          }
          $sto-border.execute($map, 2, $from, $to  , $border<from>, $border<to  >, $lon, $lat, $border<colour>);
          $sto-border.execute($map, 2, $to  , $from, $border<to  >, $border<from>, $lon, $lat, $border<colour>);
        }
      }
    }

    # No level 1 borders, since there is only one big area.
    # No exterior small areas, since there is only one big area

    $sto-mesg.execute($map, DateTime.now.Str, 'INIT');
  }

}


=begin POD

=encoding utf8

=head1 NAME

init-plat.raku -- initialising the graphs for the platonic solids

=head1 DESCRIPTION

This  programme reads  a  file listing  all nodes  and  edges for  the
platonic solids' graphs and store  them in the database. Tables filled
are: C<Maps>, C<Regions> and C<Borders>.

=head1 USAGE

  sqlite3 Hamilton.db < cr.sql
  raku init-plat.raku --fname=platonic.txt

=head2 Parameter

=head2 fname

The path of the file containing the description of the graphs

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<init-fr.raku> program.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2024 Jean Forget, all rights reserved

This  program is  published under  the  same conditions  as Raku:  the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
