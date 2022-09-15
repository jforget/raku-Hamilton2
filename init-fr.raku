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

# No this is not a Bobby Tables problem. All table names are controlled by the programme,
# they do not come from an external source.
for <Maps Areas Borders Paths Path_Relations Messages> -> $table {
  $dbh.execute("delete from $table where map in ('fr1970', 'fr2015', 'frreg');");
}

$dbh.execute(q:to/SQL/);
insert into Maps values ('fr1970', 'Départements dans les régions de 1970', 0, 0);
SQL

$dbh.execute(q:to/SQL/);
insert into Maps values ('fr2015', 'Départements dans les régions de 2015', 0, 0);
SQL

$dbh.execute(q:to/SQL/);
insert into Maps values ('frreg',  'Régions de 1970 dans les régions de 2015', 0, 0);
SQL

my $sto-area = $dbh.prepare(q:to/SQL/);
insert into Areas (map, level, code, name, long, lat, color, upper, nb_paths)
       values     (?,   ?,     ?,    ?,    ?,    ?,   ?,     ?    , 0)
SQL

my $sto-border = $dbh.prepare(q:to/SQL/);
insert into Borders (map, level, from_code, to_code, upper_from, upper_to, long, lat, color)
       values       (?,   ?,     ?,         ?,       ?,          ?,        ?,    ?,   ?    )
SQL

my $sto-mesg = $dbh.prepare(q:to/SQL/);
insert into Messages (map, dh, errcode, area, nb, data)
       values        (?,   ?,  ?,       '',   0,  '')
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
      my ($latx, $longx) = $color-or-coord.split(/ \s* ',' \s* /);
      my Num $long = $longx.Num;
      my Num $lat  = $latx.Num;
      $sto-area.execute('fr2015', 2, $code, $name, $long, $lat, $col2015, $reg2015);
      $sto-area.execute('fr1970', 2, $code, $name, $long, $lat, $col1970, $reg1970);
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

$dbh.execute(q:to/SQL/);
update Areas
set (long, lat) = (select avg(Small_Areas.long), avg(Small_Areas.lat)
                   from   Small_Areas
                   where  Small_Areas.map   = Areas.map
                     and  Small_Areas.upper = Areas.code)
where map in ('fr1970', 'fr2015')
  and level = 1
SQL

$dbh.execute(q:to/SQL/);
update Areas
set (long, lat) = (select Big_Areas.long, Big_Areas.lat
                   from   Big_Areas
                   where  Big_Areas.map  = 'fr2015'
                     and  Big_Areas.code = Areas.code)
where map   = 'frreg'
  and level = 1
SQL

$dbh.execute(q:to/SQL/);
update Areas
set (long, lat) = (select Big_Areas.long, Big_Areas.lat
                   from   Big_Areas
                   where  Big_Areas.map  = 'fr1970'
                     and  Big_Areas.code = Areas.code)
where map   = 'frreg'
  and level = 2
SQL

for %borders.kv -> $from, $hashto {
  for %$hashto.kv -> $to, $border {
    if $border<counter> != 2 {
      say "problem with $from → $to";
    }
    elsif $from le $to {
      my $color = 'Black';
      if $border<from1970> eq $border<to1970> {
        $color = $border<col1970>;
      }
      $sto-border.execute('fr1970', 2, $from, $to  , $border<from1970>, $border<to1970  >, 0, 0, $color);
      $sto-border.execute('fr1970', 2, $to  , $from, $border<to1970  >, $border<from1970>, 0, 0, $color);

      $color = 'Black';
      if $border<from2015> eq $border<to2015> {
        $color = $border<col2015>;
      }
      $sto-border.execute('fr2015', 2, $from, $to  , $border<from2015>, $border<to2015  >, 0, 0, $color);
      $sto-border.execute('fr2015', 2, $to  , $from, $border<to2015  >, $border<from2015>, 0, 0, $color);
    }
  }
}

# Level 1 borders, all in one go
$dbh.execute(q:to/SQL/);
insert into Borders (map, level, from_code,  to_code,  upper_from, upper_to, long, lat, color)
     select distinct map, 1,     upper_from, upper_to, '',         '',       0,    0,   'Black'
     from   Small_Borders
     where  map in ('fr1970', 'fr2015')
       and  upper_from != upper_to
SQL

# Filling map 'frreg' level 1
$dbh.execute(q:to/SQL/);
insert into Borders (map,     level, from_code, to_code, upper_from, upper_to, long, lat, color)
     select         'frreg',  1,     from_code, to_code, '',         '',       0,    0,   'Black'
     from  Big_Borders
     where map = 'fr2015'
SQL

# Filling map 'frreg' level 2, with a problem on the color
$dbh.execute(q:to/SQL/);
insert into Borders (map,     level, from_code,   to_code,   upper_from, upper_to, long, lat, color)
     select         'frreg',  2,     B.from_code, B.to_code, F.upper,    T.upper,  0,    0,   F.color
     from  Big_Borders B
        ,  Small_Areas F
        ,  Small_Areas T
     where B.map  = 'fr1970'
       and F.map  = 'frreg'
       and F.code = B.from_code
       and T.map  = 'frreg'
       and T.code = B.to_code
SQL

# Fixing the color problem on map 'frreg' level 2
$dbh.execute(q:to/SQL/);
update Borders
set    color = 'Black'
where  map  = 'frreg'
  and  level = 2
  and  upper_from != upper_to
SQL

# Fixing the border between Seine-et-Marne and Val-d'Oise
$dbh.execute(q:to/SQL/);
update Borders
   set  long =  2.5
     ,  lat  = 49.1
where map in ('fr1970', 'fr2015')
and   level = 2
and  (   (from_code = '77' and to_code = '95')
      or (from_code = '95' and to_code = '77'))
SQL

for <fr1970 fr2015 frreg> -> $map {
  $sto-mesg.execute($map, DateTime.now.Str, 'INIT');
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
