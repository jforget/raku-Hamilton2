#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Pour les cartes suffisamment simples, mise à plat des chemins complets génériques en chemins spécifiques
#     For simple enough maps, flatten generic full paths into specific full paths
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

my $sto-mesg = $dbh.prepare(q:to/SQL/);
insert into Messages (map, dh, errcode, area, nb, data)
       values        (?,   ?,  ?,       ?,    ?,  ?)
SQL

my $select-generic = $dbh.prepare(q:to/SQL/);
select path, first_num, paths_nb, macro_num
from   Full_Paths
where  map = ?
SQL

my $sth1 = $dbh.prepare(q:to/SQL/);
select path
from   Region_Paths
where map  = ?
  and area = ?
  and num  = ?
SQL

my $sth2 = $dbh.prepare(q:to/SQL/);
select 'X'
from   Small_Borders
where  map       = ?
  and  from_code = ?
  and  to_code   = ?
SQL

my $sto-path = $dbh.prepare(q:to/SQL/);
insert into Paths (map, level, area, num, path, from_code, to_code, cyclic, macro_num, generic_num, first_num, paths_nb, fruitless, fruitless_reason, nb_full_paths, num_s2g)
       values     (?,   ?,     ?,    ?,   ?,    ?,         ?,       ?,      ?,         0,           ?,         ?,        0,         '',               0,             0)
SQL

my $sto-relation = $dbh.prepare(q:to/SQL/);
insert into Path_Relations (map, full_num, area, region_num, range1, coef1, coef2)
       values              (?,   ?,        ?,    ?,          ?,      ?,     ?)
SQL
my $sth-check-cyclic = $dbh.prepare(q:to/SQL/);
select 'X'
from   Borders
where  map       = ?
  and  level     = 2
  and  from_code = ?
  and  to_code   = ?
SQL

sub MAIN (
      Str  :$map             #= The code of the map
    ) {

  my %map = access-sql::read-map(~ $map);
  unless %map {
    die "Unkown map $map";
  }
  my Int $nb-full = %map<nb_full>;
  if $nb-full == 0 {
    die "Map $map has no full paths";
  }
  if $nb-full > full-path-threshold() {
    die "Map $map has too many full paths: $nb-full";
  }
  my Int $max-macro = %map<nb_macro>;

  my $check = $dbh.execute('select path from Full_Paths where map = ?', $map).row(:hash);
  unless $check<path>.contains(')') {
    die "Specific paths already built for $map";
  }

  my Int $increment = commit-interval();
  my Int $threshold = $increment;
  my Int $counter   = 0;
  say "{DateTime.now.hh-mm-ss} beginning the generation of specific full paths for $map";
  # Initial clean-up
  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths          where map = ? and level = 5"          , $map);
  $dbh.execute("delete from Path_Relations where map = ?"                        , $map);
  $dbh.execute("delete from Messages       where map = ? and errcode like 'FLA_'", $map);
  $sto-mesg.execute($map, DateTime.now.Str, 'FLA1', '', 0, '');
  $dbh.execute("commit");
  my Int $path-number = 0;

  # Building the specific paths with a provisional level 5
  $dbh.execute("begin transaction");
  for $select-generic.execute($map).allrows(:array-of-hash) -> %generic {
    #say %generic;
    my Str $gen-path= %generic<path>;
    my     @words   = $gen-path.comb( / \w+ / );
    my Str @t-area  = @words[0, 3 ... *];
    my Int @t-first = @words[1, 4 ... *].map({ +$_ });
    my Int @t-coef  = @words[2, 5 ... *].map({ +$_ }).reverse;
    for 0 ..^ %generic<paths_nb> -> $rel-num {
      my $abs-num = $rel-num +  %generic<first_num>;

      my @t-index = $rel-num.polymod(@t-coef).reverse[1...*];
      #say $abs-num, ' ', $rel-num, ' ', @t-index;
      my $path = $gen-path;
      for @t-area.kv -> $i, $area {
        my $reg-num = @t-first[$i] + @t-index[$i];
        my @reg-val = $sth1.execute($map, $area, $reg-num).row(:hash);
        $path ~~ s/ '(' .*? ')' /@reg-val[0]<path>/;
        $sto-relation.execute($map, $abs-num, $area, $reg-num, 1, 0, 0);
      }
      #say $abs-num, ' ', $path;
      my $from_code = $path.match(/^ \w+ /).Str;
      my $to_code   = $path.match(/ \w+ $/).Str;
      my $cyclic-check = $sth2.execute($map, $from_code, $to_code).row;
      my $cyclic = 0;
      if $cyclic-check[0] // '' eq 'X' {
        $cyclic = 1;
      }
      $sto-path.execute($map, 5, '', $abs-num, $path, $from_code, $to_code, $cyclic, %generic<macro_num>, $abs-num, 1);
      $counter++;
      if $counter ≥ $threshold {
        $dbh.execute("commit");
        $dbh.execute("begin transaction");
        say "{DateTime.now.hh-mm-ss} updates so far: $counter";
        $threshold += $increment;
      }
    }
  }
  $dbh.execute("commit");

  # Giving the proper level 3 to specific paths
  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths where map = ? and level = 3", $map);
  $dbh.execute(q:to/SQL/, $map);
  update Paths
  set    level = 3
  where  map   = ?
  and    level = 5
  SQL
  $dbh.execute("commit");

  # Last step, the report
  $dbh.execute("begin transaction");
  $dbh.execute("update Maps set specific_paths = 1 where map = ?", $map);
  $sto-mesg.execute($map, DateTime.now.Str, 'FLA2', '', 0, '');
  $dbh.execute("commit");
  say "{DateTime.now.hh-mm-ss} the end";

}

=begin POD

=encoding utf8

=head1 NAME

gener3.raku -- flattening generic full Hamiltonian paths into specific full Hamiltonian paths

=head1 DESCRIPTION

This programme generates specific  full Hamiltonian paths from generic
full Hamiltonian paths.

=head1 USAGE

  raku gener3.raku --map=frreg

=head1 PARAMETER

=head2 map

The code of the map, e.g. C<frreg>.

=head1 OTHER ELEMENTS

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<gener1.raku> and F<gener2.raku> programmes.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2024 Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
