# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Partie "modèle" du serveur web permettant de consulter la base Hamilton.db des chemins doublement hamiltoniens
#     Model part of the MVC web server which displays the database storing doubly-Hamiltonian paths
#     Copyright (C) 2022 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

unit module access-sql;

use DBIish;
use db-conf-sql;

my $dbh = DBIish.connect('SQLite', database => dbname());


our sub list-maps {
  my $sth = $dbh.prepare("select map, name, nb_macro, nb_full from Maps");
  my @maps = $sth.execute().allrows;
  #say @maps;
  return @maps;
}

our sub read-map(Str $map) {
  my $sth = $dbh.prepare("select map, name, nb_macro, nb_full from Maps where map = ?");
  my %val = $sth.execute($map).row(:hash);
  return %val;
}

our sub read-region(Str $map, Str $region) {
  my $sth = $dbh.prepare("select * from Big_Areas where map = ? and code = ?");
  my @val = $sth.execute($map, $region).row(:hash);
  return @val;
}

our sub list-big-areas(Str $map) {
  my $sth = $dbh.prepare("select * from Big_Areas where map = ?");
  my @val = $sth.execute($map).allrows(:array-of-hash);
  return @val;
}

our sub list-small-areas(Str $map) {
  my $sth = $dbh.prepare("select * from Small_Areas where map = ?");
  my @val = $sth.execute($map).allrows(:array-of-hash);
  return @val;
}

our sub list-areas-in-region(Str $map, Str $region) {
  my $sth = $dbh.prepare("select * from Small_Areas where map = ? and upper = ?");
  my @val = $sth.execute($map, $region).allrows(:array-of-hash);
  return @val;
}

our sub list-neighbour-areas(Str $map, Str $region) {
  my $sth = $dbh.prepare(q:to/SQL/);
  select A.map map, A.code code, A.name name, A.long long, A.lat lat, A.color color, A.upper upper
  from Small_Borders B
  join Small_Areas   A
    on   A.map  = B.map
    and  A.code = B.to_code
  where B.map = ? and B.upper_from = ?
    and B.upper_to != B.upper_from
  SQL
  my @val = $sth.execute($map, $region).allrows(:array-of-hash);
  return @val;
}

our sub list-big-borders(Str $map) {
  my $sth = $dbh.prepare(q:to/SQL/);
  select B.from_code code_f, B.to_code code_t, 'Black' color
       , F.long long_f, F.lat lat_f
       , T.long long_t, T.lat lat_t
       , B.long long_m, B.lat lat_m
  from Big_Borders B
  join Big_Areas F
    on  F.map  = B.map
    and F.code = B.from_code
  join Big_Areas T
    on  T.map  = B.map
    and T.code = B.to_code
  where B.map = ?
  SQL
  my @val = $sth.execute($map).allrows(:array-of-hash);
  return @val;
}

our sub list-small-borders(Str $map) {
  my $sth = $dbh.prepare(q:to/SQL/);
  select B.from_code code_f, B.to_code code_t, B.color color
       , F.long long_f, F.lat lat_f
       , T.long long_t, T.lat lat_t
       , B.long long_m, B.lat lat_m
  from Small_Borders B
  join Small_Areas F
    on  F.map  = B.map
    and F.code = B.from_code
  join Small_Areas T
    on  T.map  = B.map
    and T.code = B.to_code
  where B.map = ?
  SQL
  my @val = $sth.execute($map).allrows(:array-of-hash);
  return @val;
}

# This routine extracts all department borders inside a region
# PLUS all department borders across a region border
our sub list-borders-for-region(Str $map, Str $region) {
  my $sth = $dbh.prepare(q:to/SQL/);
  select B.from_code code_f, B.to_code code_t, B.color color
       , F.long long_f, F.lat lat_f
       , T.long long_t, T.lat lat_t
       , B.long long_m, B.lat lat_m
  from Small_Borders B
  join Small_Areas F
    on  F.map  = B.map
    and F.code = B.from_code
  join Small_Areas T
    on  T.map  = B.map
    and T.code = B.to_code
  where B.map = ?
  and   B.upper_from = ?
  SQL
  my @val = $sth.execute($map, $region).allrows(:array-of-hash);
  return @val;
}

our sub list-messages(Str $map) {
  my $sth = $dbh.prepare("select * from Messages where map = ? order by dh");
  my @val = $sth.execute($map).allrows(:array-of-hash);
  return @val;
}

our sub list-regional-messages(Str $map, Str $region) {
  my $sth = $dbh.prepare(q:to/SQL/);
  select *
  from Messages
  where map = ?
  and  (errcode = 'INIT'
     or area    = ?)
  order by dh
  SQL
  my @val = $sth.execute($map, $region).allrows(:array-of-hash);
  return @val;
}

our sub read-path(Str $map, Int $level, Str $area, Int $num) {
  my $sth = $dbh.prepare("select * from Paths where map = ? and level = ? and area = ? and num = ?");
  my %val = $sth.execute($map, $level, $area, $num).row(:hash);
  return %val;
}

our sub max-path-number(Str $map, Int $level, Str $area) {
  my $sth = $dbh.prepare("select max(num) from Paths where map = ? and level = ? and area = ?");
  my @val = $sth.execute($map, $level, $area).row;
  return @val[0];
}

our sub full-path-interval(Str $map, Int $path-num) {
  my $sth = $dbh.prepare("select ifnull(min(num), 0), ifnull(max(num), 0) from Full_Paths where map = ? and macro_num = ?");
  my @val = $sth.execute($map, $path-num).row;
  return @val;
}

=begin POD

=encoding utf8

=head1 NAME

access-sql.rakumod -- utility module to access the Hamilton database

=head1 DESCRIPTION

This module manages  the accesses to the SQLite  Hamilton database. It
is used internally by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
