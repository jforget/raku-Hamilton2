#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Initialisation des cartes de France avec les départements, les régions de 2015 et les régions de 1970
#     Initialising the maps of France with departments, Y2015 regions and Y1970 regions.
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;


my Str $fname = 'fr-depts.txt';
my $dbh = DBIish.connect('SQLite', database => dbname());

$dbh.execute(q:to/SQL/);
delete from Maps where map in ('fr1970', 'fr2015', 'frreg');
SQL

$dbh.execute(q:to/SQL/);
delete from Areas where map in ('fr1970', 'fr2015', 'frreg');
SQL

$dbh.execute(q:to/SQL/);
delete from Borders where map in ('fr1970', 'fr2015', 'frreg');
SQL

$dbh.execute(q:to/SQL/);
insert into Maps values ('fr1970', 'Départements dans les régions de 1970');
SQL

$dbh.execute(q:to/SQL/);
insert into Maps values ('fr2015', 'Départements dans les régions de 2015');
SQL

$dbh.execute(q:to/SQL/);
insert into Maps values ('frreg',  'Régions de 1970 dans les régions de 2015');
SQL

my $sto-area = $dbh.prepare(q:to/SQL/);
insert into Areas (map, level, code, name, long, lat, color, upper)
       values     (?,   ?,     ?,    ?,    ?,    ?,   ?,     ?    )
SQL

my Str $reg1970;
my Str $reg2015;
my Str $col1970;
my Str $col2015;
my %borders;

my $fh = $fname.IO.open(:r);
for $fh.lines -> Str $line {
  my ($lvl, $code, $name, $color-or-coord, $borders) = $line.split(/ \s* ';' \s*/);
  $color-or-coord //= '';
  given $lvl {
    when 'AB' {
      $reg1970 = ~ $code;
      $reg2015 = ~ $code;
      $col1970 = ~ $color-or-coord;
      $col2015 = ~ $color-or-coord;
      $sto-area.execute('fr2015', 1, $reg2015, $name, 0, 0, $col2015, '');
      $sto-area.execute('frreg' , 1, $reg2015, $name, 0, 0, $col2015, '');
      $sto-area.execute('fr1970', 1, $reg1970, $name, 0, 0, $col1970, '');
      $sto-area.execute('frreg' , 2, $reg1970, $name, 0, 0, $col2015, $reg2015);
    }
    when 'A' {
      $reg2015 = ~ $code;
      $col2015 = ~ $color-or-coord;
      $sto-area.execute('fr2015', 1, $reg2015, $name, 0, 0, $col2015, '');
      $sto-area.execute('frreg' , 1, $reg2015, $name, 0, 0, $col2015, '');
    }
    when 'B' {
      $reg1970 = ~ $code;
      $col1970 = ~ $color-or-coord;
      $sto-area.execute('fr1970', 1, $reg1970, $name, 0, 0, $col1970, '');
      $sto-area.execute('frreg' , 2, $reg1970, $name, 0, 0, $col2015, $reg2015);
    }
    when 'C' {
      my ($longx, $latx) = $color-or-coord.split(/ \s* ',' \s* /);
      my Num $long = $longx.Num;
      my Num $lat  = $latx.Num;
      $sto-area.execute('fr2015', 1, $code, $name, $long, $lat, $col2015, $reg2015);
      $sto-area.execute('fr1970', 1, $code, $name, $long, $lat, $col1970, $reg1970);
      for $borders.split(/ \s* ',' \s*/) -> $neighbour {
        %borders{$code}{$neighbour}<counter>++;
        %borders{$code}{$neighbour}<from1970> = $reg1970;
        %borders{$code}{$neighbour}<from2015> = $reg2015;
        %borders{$code}{$neighbour}<col1970>  = $col1970;
        %borders{$code}{$neighbour}<col2015>  = $col2015;

        %borders{$neighbour}{$code}<counter>++;
        %borders{$neighbour}{$code}<to1970> = $reg1970;
        %borders{$neighbour}{$code}<to2015> = $reg2015;
      }
    }
  }
}
$fh.close;

for %borders.kv -> $from, $hashto {
  for %$hashto.kv -> $to, $border {
    if $border<counter> != 2 {
      say "problem with $from → $to";
    }
  }
}

=begin POD

=encoding utf8

=head1 NAME

init-fr.raku -- initialising the region+department maps of France

=head1 DESCRIPTION

This programme  reads a file  listing all departments and  regions for
France and  store them  in the database.  Tables filled  are: C<Maps>,
C<Regions> and C<Borders>.

=head1 USAGE

  sqlite3 Hamilton.db < cr.sql
  raku init-fr.raku

=head2 Parameters

None.

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<init-fr.raku> program.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2022, Jean Forget, all rights reserved

This  program is  published under  the  same conditions  as Raku:  the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
