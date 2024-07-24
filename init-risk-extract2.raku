#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Initialisation de la carte de Risk
#     Initialising the map of Risk
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;

my $map   = 'x-risk2';
my $name  = 'Extract from the Risk map';
my Str $fname = 'Risk-extract2.txt';
my $dbh = DBIish.connect('SQLite', database => dbname());

# Longitudes
my Num $lon-Kod = -154.Num;  # 56°N 154°W Kodiak Island
my Num $lon-Aus =  142.Num;  # 10°S 142°E cap de l'Australie
my Num $x-Kod   =  56.Num;
my Num $x-Aus   = 715.Num;
my Num $a-lon   = ($lon-Aus - $lon-Kod) / ($x-Aus - $x-Kod);
my Num $b-lon   = $lon-Kod - $a-lon × $x-Kod;
sub conv-lon(Num $x --> Num) { return $a-lon × $x + $b-lon }

# Latitudes
my Num $lat-Aus = -10.Num;  # 10°S 142°E cap de l'Australie
my Num $lat-Kod =  56.Num;  # 56°N 154°W Kodiak Island
my Num $y-Aus   = 392.Num;
my Num $y-Kod   = 116.Num;
my Num $a-lat   = ($lat-Kod - $lat-Aus) / ($y-Kod - $y-Aus);
my Num $b-lat   = $lat-Aus - $a-lat × $y-Aus;
sub conv-lat(Num $y --> Num) { return $a-lat × $y + $b-lat }

# No this is not a Bobby Tables problem. All table names are controlled by the programme,
# they do not come from an external source.
for <Maps Areas Borders Paths Path_Relations Messages> -> $table {
  $dbh.execute("delete from $table where map = ?;", $map);
}

$dbh.execute(q:to/SQL/, $map, $name);
insert into Maps (map, name, nb_macro, nb_full, nb_generic, specific_paths, fruitless_reason, with_scale, with_isom, full_diameter, full_radius, macro_diameter, macro_radius)
          values (?  , ?   , 0       , 0      , 0         , 0             , ''              , 1         , 0        , 0            , 0          , 0             , 0);
SQL

my $sto-area = $dbh.prepare(q:to/SQL/);
insert into Areas (map, level, code, name, long, lat, color, upper, nb_macro_paths, nb_macro_paths_1, nb_region_paths, exterior)
       values     (?,   ?,     ?,    ?,    ?,    ?,   ?,     ?    , 0,              0,                0,               0)
SQL

my $sto-border = $dbh.prepare(q:to/SQL/);
insert into Borders (map, level, from_code, to_code, upper_from, upper_to, long, lat, color, fruitless, nb_paths, nb_paths_1, cross_idl)
       values       (?,   ?,     ?,         ?,       ?,          ?,        ?,    ?,   ?    , 0,         0,        0         , ?)
SQL

my $sto-mesg = $dbh.prepare(q:to/SQL/);
insert into Messages (map, dh, errcode, area, nb, data)
       values        (?,   ?,  ?,       '',   0,  '')
SQL

my $upd-big-borders = $dbh.prepare(q:to/SQL/);
update Borders
   set cross_idl = 1
     , long      = ?
     , lat       = ?
where  map       = ?
and    level     = 1
and    from_code = ?
and    to_code   = ?
SQL

my $upd-small-borders = $dbh.prepare(q:to/SQL/);
update Borders
   set cross_idl  = 1
where  map        = ?
and    level      = 2
and    upper_from = ?
and    upper_to   = ?
SQL

sub MAIN(Bool :$complete = False) {
  my Str $upper;
  my Str $color;
  my %borders;
  my %middle-big;
  my %middle-small;
  my %seen;
  my %area;
  my %cross-idl;

  my $fh = $fname.IO.open(:r);
  for $fh.lines -> Str $line {
    my ($lvl, $code, $name, $color-or-x, $y, $borders) = $line.split(/ \s* ';' \s*/);
    given $lvl {
      when 'A' {
        $upper = $code;
        $color = $color-or-x;
        $sto-area.execute($map, 1, $code, $name, 0, 0, $color, '');
      }
      when 'B' {
        my Num $lon = conv-lon($color-or-x.Num);
        my Num $lat = conv-lat($y.Num);
        %seen{$code} = 1;
        $sto-area.execute($map, 2, $code, $name, $lon, $lat, $color, $upper);

        for $borders.split(/ \s* ',' \s*/) -> $neighb {
          my Str $neighbour = $neighb.uc;
          %borders{$code}{$neighbour}<counter>++;
          %borders{$code}{$neighbour}<fromup> = $upper;
          %borders{$code}{$neighbour}<color>  = $color;

          %borders{$neighbour}{$code}<counter>++;
          %borders{$neighbour}{$code}<toup> = $upper;
        }
        %area{$code} = 1;
      }
      when 'X' {
        my Num $lon = conv-lon($color-or-x.Num);
        my Num $lat = conv-lat($y.Num);
        %middle-big{$code}{$name}<lon> = $lon;
        %middle-big{$name}{$code}<lat> = $lat;
      }
      when 'Y' {
        my Num $lon = conv-lon($color-or-x.Num);
        my Num $lat = conv-lat($y.Num);
        %middle-small{$code}{$name}<lon> = $lon;
        %middle-small{$name}{$code}<lat> = $lat;
        %cross-idl{   $code}{$name} = True;
      }
    }
  }
  $fh.close;

  # Longitude and latitude in the big area are computed with the average of lon/lat for cities
  $dbh.execute(q:to/SQL/, $map);
  update Areas
  set (long, lat) = (select avg(Small_Areas.long), avg(Small_Areas.lat)
                     from   Small_Areas
                     where  Small_Areas.map   = Areas.map
                       and  Small_Areas.upper = Areas.code)
  where map   = ?
    and level = 1
  SQL

  for %borders.kv -> $from, $hashto {
    for %$hashto.kv -> $to, $border {
      if $border<counter> != 2 {
        if (%seen{$from} // 0) == 1 && (%seen{$to} // 0) == 1 or $complete {
          say "problem with $from → $to";
        }
      }
      elsif $from le $to {
        my Str $color = 'Black';
        my Num $lon   = 0e0;
        my Num $lat   = 0e0;
        if %middle-small{$from}{$to} {
          $lon = %middle-small{$from}{$to}<lon>;
          $lat = %middle-small{$from}{$to}<lat>;
        }
        if $border<fromup> eq $border<toup> {
          $color = $border<color>;
        }
        my $cross-idl = %cross-idl{$from}{$to} // 0;
        $sto-border.execute($map, 2, $from, $to  , $border<fromup>, $border<toup>, $lon, $lat, $color, $cross-idl);
        if $cross-idl {
          $lon = %middle-small{$to}{$from}<lon>;
          $lat = %middle-small{$to}{$from}<lat>;
          $sto-border.execute($map, 2, $to  , $from, $border<toup>, $border<fromup>, $lon, $lat, $color, 1);
        }
        else {
          $sto-border.execute($map, 2, $to  , $from, $border<toup>, $border<fromup>, $lon, $lat, $color, 0);
        }

      }
    }
  }

  # Level 1 borders, all in one go
  $dbh.execute(q:to/SQL/, $map);
  insert into Borders (map, level, from_code,  to_code,  upper_from, upper_to, long, lat, fruitless, color,   nb_paths, nb_paths_1, cross_idl)
       select distinct map, 1,     upper_from, upper_to, '',         '',       0,    0,   0,         'Black', 0,        0         , 0
       from   Small_Borders
       where  map = ?
         and  upper_from != upper_to
  SQL

  for %middle-big.kv -> $from, $hashto {
    for $hashto.kv -> $to, $middle {
      $upd-big-borders  .execute($middle<lon>, $middle<lat>, $map, $from, $to);
    }
  }

  # Filling the "exterior" field
  $dbh.execute(q:to/SQL/, $map);
  update Areas
    set  exterior = 1
  where map = ?
  and   level = 2
  and   exists (select 'X'
                from  Small_Borders B
                where B.map        = Areas.map
                and   B.from_code  = Areas.code
                and   B.upper_to  != Areas.upper)
  SQL

  $sto-mesg.execute($map, DateTime.now.Str, 'INIT');
}

=begin POD

=encoding utf8

=head1 NAME

init-risk-extract2.raku -- initialising the graph for a partial Risk map

=head1 DESCRIPTION

This programme reads a file listing  all nodes and edges for a partial
Risk map,  used as a showcase  for the "crossing the  IDL" feature and
store them in the database. Tables filled are: C<Maps>, C<Regions> and
C<Borders>.

=head1 USAGE

  sqlite3 Hamilton.db < cr.sql
  raku init-risk-extract2.raku

=head2 Parameter

Boolean parameter  C<complete>. If C<True>,  that means that  the data
file 'Risk-extract2.txt' is complete and that the programme must check
the inconsistent border declarations. If C<False>, that means that the
data file  is not complete  and that checking for  inconsistent border
declarations is irrelevant.

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<init-fr.raku> program.

The filename  of the text  containing the list  of nodes and  edges is
hard-coded in the programme.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2024 Jean Forget, all rights reserved

This  program is  published under  the  same conditions  as Raku:  the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
