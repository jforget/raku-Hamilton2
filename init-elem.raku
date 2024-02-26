#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Initialisation de graphes élémentaires
#     Initialising elementary graphs
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;

sub MAIN (
      Int :$nb where 3 ≤ * ≤ 9 = 5   #= The number characteristic
    ) {

  my $dbh = DBIish.connect('SQLite', database => dbname());
  my Int $radius = 100;
  my Int $prism-radius = 30;

  my @type = <P C W S Y AY>;
  my %map;
  for @type -> Str $type {
    my $map;
    given $type {
      when 'P'|'C'|'Y'|'AY' { $map = sprintf("%s%d", $type, $nb); }
      when 'S'|'W'          { $map = sprintf("%s%d", $type, $nb + 1); }
    }
    %map{$type} = $map;
    # No this is not a Bobby Tables problem. All table names are controlled by the programme,
    # they do not come from an external source.
    for <Maps Areas Borders Paths Path_Relations Exit_Borders Messages> -> $table {
      $dbh.execute("delete from $table where map = ?;", $map);
    }
  }

  my $sto-area = $dbh.prepare(q:to/SQL/);
  insert into Areas (map, level, code, name, long, lat, color, upper, nb_macro_paths, nb_macro_paths_1, nb_region_paths, exterior)
         values     (?,   ?,     ?,    ?,    ?,    ?,   ?,     ?    , 0,              0,                0,               0)
  SQL

  my $sto-border = $dbh.prepare(q:to/SQL/);
  insert into Borders (map, level, from_code, to_code, upper_from, upper_to, long, lat, color, fruitless, nb_paths, nb_paths_1, cross_idl)
         values       (?,   ?,     ?,         ?,       ?,          ?,        ?,    ?,   ?    , 0,         0,        0         , 0)
  SQL

  my $sto-mesg = $dbh.prepare(q:to/SQL/);
  insert into Messages (map, dh, errcode, area, nb, data)
         values        (?,   ?,  ?,       '',   0,  '')
  SQL

  my Str $region;
  my Str $colour = 'Blue';
  my %borders;
  my Num $ε = 1e-8; # to prevent SQLite from storing and retrieving Num's as Int's
  my Str $alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXY';
  my Str $first-ring  = $alphabet.substr(0  , $nb);
  my Str $second-ring = $alphabet.substr($nb, $nb);

  for @type -> $type {
    my Str $label;
    my Str $map = %map{$type};
    given $type {
      when 'P'   { $label = "Path with $nb nodes"; }
      when 'C'   { $label = "Circle with $nb nodes"; }
      when 'W'   { $label = "Wheel with $nb spokes"; }
      when 'S'   { $label = "Star with $nb rays"; }
      when 'Y'   { $label = "Prism with two {$nb}-sided faces"; }
      when 'AY'  { $label = "Antiprism with two {$nb}-sided faces"; }
    }
    $dbh.execute(q:to/SQL/, $map, $label);
    insert into Maps (map, name, nb_macro, nb_full, nb_generic, fruitless_reason, with_scale, with_isom)
              values (?  , ?   , 0       , 0      , 0         , ''              , 0         , 0);
    SQL
    $sto-area.execute($map, 1, $map, $label, 0, 0, $colour, '');
    if $type eq 'W' | 'S' {
      $sto-area.execute($map, 2, 'Z', "Centre", $ε, $ε, $colour, $map);
    }
  }

  for 0..^$nb -> $angle {
    my Num $long = $radius.Num × cos( $angle.Num × 2 × π / $nb + π / 2) + $ε;
    my Num $lat  = $radius.Num × sin( $angle.Num × 2 × π / $nb + π / 2) + $ε;
    my Str $code = $first-ring.substr($angle, 1);
    for @type -> $type {
      my Str $map = %map{$type};
      $sto-area.execute($map , 2, $code, $code, $long, $lat, $colour, $map);
    }

    %borders<W>{$code}<Z>++;
    %borders<W><Z>{$code}++;

    %borders<S>{$code}<Z>++;
    %borders<S><Z>{$code}++;

    my Str $code1 = $second-ring.substr($angle, 1);
    $long = $prism-radius.Num × cos( $angle.Num × 2 × π / $nb + π / 2) + $ε;
    $lat  = $prism-radius.Num × sin( $angle.Num × 2 × π / $nb + π / 2) + $ε;
    $sto-area.execute(%map<Y>, 2, $code1, $code, $long, $lat, $colour, %map<Y>);
    %borders<Y>{$code }{$code1}++;
    %borders<Y>{$code1}{$code }++;

    $long = $prism-radius.Num × cos( ($angle.Num × 2 + 1) × π / $nb + π / 2) + $ε;
    $lat  = $prism-radius.Num × sin( ($angle.Num × 2 + 1) × π / $nb + π / 2) + $ε;
    $sto-area.execute(%map<AY>, 2, $code1, $code, $long, $lat, $colour, %map<AY>);
    %borders<AY>{$code }{$code1}++;
    %borders<AY>{$code1}{$code }++;

    $code1 = $first-ring.substr(($angle + 1) % $nb, 1);
    for <C W Y AY> -> $type {
      %borders{$type}{$code }{$code1}++;
      %borders{$type}{$code1}{$code }++;
    }
    if $code1 ne 'A' {
      %borders<P>{$code }{$code1}++;
      %borders<P>{$code1}{$code }++;
    }
    $code  = $second-ring.substr($angle, 1);
    $code1 = $second-ring.substr(($angle + 1) % $nb, 1);
    %borders<Y>{$code }{$code1}++;
    %borders<Y>{$code1}{$code }++;
    %borders<AY>{$code }{$code1}++;
    %borders<AY>{$code1}{$code }++;
    $code1 = $first-ring.substr(($angle + 1) % $nb, 1);
    %borders<AY>{$code }{$code1}++;
    %borders<AY>{$code1}{$code }++;
  }

  for @type -> $type {
    my Str $map = %map{$type};
    $dbh.execute(q:to/SQL/, $map);
    update Areas
    set (long, lat) = (select avg(Small_Areas.long), avg(Small_Areas.lat)
                       from   Small_Areas
                       where  Small_Areas.map   = Areas.map
                         and  Small_Areas.upper = Areas.code)
    where map   = ?
      and level = 1
    SQL

    for %borders{$type}.kv -> $from, $hashto {
      for %$hashto.kv -> $to, $border {
        if $from le $to {
          $sto-border.execute($map, 2, $from, $to  , $map, $map, 0, 0, $colour);
          $sto-border.execute($map, 2, $to  , $from, $map, $map, 0, 0, $colour);
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

init-elem.raku -- initialising elementary graphs

=head1 DESCRIPTION

This  programme  initialises elementary  graphs  for  a given  number:
circle with I<n> nodes, star  with I<n> rays (therefore I<n>+1 nodes),
wheel with I<n> spokes (therefore I<n>+1 nodes), prism with I<n>-sided
polygons (therefore 2×I<n> nodes),  antiprism with I<n>-sided polygons
(therefore 2×I<n> nodes).

=head1 USAGE

  sqlite3 Hamilton.db < cr.sql
  raku init-elem.raku --nb=4

=head2 Parameters

=head2 nb

The characteristic number of the graphs. Default value is 5.

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<init-fr.raku> program.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2023, 2024 Jean Forget, all rights reserved

This  program is  published under  the  same conditions  as Raku:  the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
