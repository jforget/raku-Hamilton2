#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Initialisation de la carte du jeu icosien
#     Initialising the map of the icosian game
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;


my Str $fname = 'icosian.txt';
my $dbh = DBIish.connect('SQLite', database => dbname());

# No this is not a Bobby Tables problem. All table names are controlled by the programme,
# they do not come from an external source.
for <Maps Areas Borders Paths Path_Relations Exit_Borders Messages> -> $table {
  $dbh.execute("delete from $table where map = 'ico';");
}

$dbh.execute(q:to/SQL/);
insert into Maps values ('ico', 'Icosian game', 0, 0, 0, '');
SQL

my $sto-area = $dbh.prepare(q:to/SQL/);
insert into Areas (map, level, code, name, long, lat, color, upper, nb_paths, exterior)
       values     (?,   ?,     ?,    ?,    ?,    ?,   ?,     ?    , 0,        0)
SQL

my $sto-border = $dbh.prepare(q:to/SQL/);
insert into Borders (map, level, from_code, to_code, upper_from, upper_to, long, lat, color, fruitless)
       values       (?,   ?,     ?,         ?,       ?,          ?,        ?,    ?,   ?    , 0)
SQL

my $sto-mesg = $dbh.prepare(q:to/SQL/);
insert into Messages (map, dh, errcode, area, nb, data)
       values        (?,   ?,  ?,       '',   0,  '')
SQL

my Str $region;
my Str $colour;
my %borders;

my $fh = $fname.IO.open(:r);
for $fh.lines -> Str $line {
  my ($lvl, $code, $name, $color-or-coord, $borders) = $line.split(/ \s* ';' \s*/);
  $color-or-coord //= '';
  given $lvl {
    when 'A' {
      $region = ~ $code;
      $colour = ~ $color-or-coord;
      $sto-area.execute('ico', 1, $region, $name, 0, 0, $colour, '');
    }
    when 'B' {
      my ($rayonx, $anglex) = $color-or-coord.split(/ \s* ',' \s* /);
      my Num $long = $rayonx.Num × cos( $anglex.Num × pi / 5 + pi / 2) + 1e-8;
      my Num $lat  = $rayonx.Num × sin( $anglex.Num × pi / 5 + pi / 2) + 1e-8;
      $sto-area.execute('ico' , 2, $code, $name, $long, $lat, $colour, $region);

      for $borders.split(/ \s* ',' \s*/) -> $neighbour {
        %borders{$code}{$neighbour}<counter>++;
        %borders{$code}{$neighbour}<from>   = $region;
        %borders{$code}{$neighbour}<colour> = $colour;

        %borders{$neighbour}{$code}<counter>++;
        %borders{$neighbour}{$code}<to> = $region;
      }
    }
  }
}
$fh.close;

$dbh.execute(q:to/SQL/);
update Areas
set (long, lat) = (select avg(Small_Areas.long), avg(Small_Areas.lat)
                   from   Small_Areas
                   where  Small_Areas.map   = Areas.map
                     and  Small_Areas.upper = Areas.code)
where map   = 'ico'
  and level = 1
SQL

for %borders.kv -> $from, $hashto {
  for %$hashto.kv -> $to, $border {
    if $border<counter> != 2 {
      say "problem with $from → $to";
    }
    elsif $from le $to {
      my $color = 'Black';
      if $border<from> eq $border<to> {
        $color = $border<colour>;
      }
      $sto-border.execute('ico', 2, $from, $to  , $border<from>, $border<to  >, 0, 0, $color);
      $sto-border.execute('ico', 2, $to  , $from, $border<to  >, $border<from>, 0, 0, $color);
    }
  }
}

# No level 1 borders, since there is only one big area.
# No exterior small areas, since there is only one big area

$sto-mesg.execute('ico', DateTime.now.Str, 'INIT');


=begin POD

=encoding utf8

=head1 NAME

init-ico.raku -- initialising the map for the Icosian game

=head1 DESCRIPTION

This  programme reads  a  file listing  all nodes  and  edges for  the
icosian  game and  store  them  in the  database.  Tables filled  are:
C<Maps>, C<Regions> and C<Borders>.

=head1 USAGE

  sqlite3 Hamilton.db < cr.sql
  raku init-ico.raku

=head2 Parameters

None.

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<init-fr.raku> program.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2023, Jean Forget, all rights reserved

This  program is  published under  the  same conditions  as Raku:  the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
