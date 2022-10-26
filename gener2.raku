#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération des chemins hamiltoniens complets à partir des macro-chemins et des chemins régionaux
#     Genetating full Hamiltonian paths using macro-paths and regional paths
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

my $sto-path = $dbh.prepare(q:to/SQL/);
insert into Paths (map, level, area, num, path, from_code, to_code, cyclic, macro_num)
       values     (?,   ?,     ?,    ?,   ?,    ?,         ?,       ?,      ?)
SQL

my $sto-relation = $dbh.prepare(q:to/SQL/);
insert into Path_Relations (map, full_num, area, region_num)
       values              (?,   ?,        ?,    ?)
SQL

my $extract-region-paths  = $dbh.prepare(q:to/SQL/);
select B.num, B.path, B.area, B.to_code
from Borders_With_Star A
join Region_Paths B
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
join Small_Areas  C
   on  C.map      = B.map
   and C.code     = B.to_code
   and C.exterior = 1
where A.map       = ?
and   A.from_code = ?
and   A.upper_to  = ?
SQL

my $extract-last-region-paths  = $dbh.prepare(q:to/SQL/);
select B.num, B.path, B.area, B.to_code
from Borders_With_Star A
join Region_Paths B
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
where A.map       = ?
and   A.from_code = ?
and   A.upper_to  = ?
SQL

sub MAIN (
      Str  :$map             #= The code of the map
    ) {

  my %map = access-sql::read-map(~ $map);
  unless %map {
    die "Unkown map $map";
  }

  # Initial clean-up
  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths          where map = ? and level = 3"          , $map);
  $dbh.execute("delete from Path_Relations where map = ?"                        , $map);
  $dbh.execute("delete from Messages       where map = ? and errcode like 'FUL_'", $map);
  $sto-mesg.execute($map, DateTime.now.Str, 'FUL1', '', 0, '');
  $dbh.execute("commit");
  my Int $path-number = 0;

  my Int $partial-paths-nb   =    0;
  my Int $partial-threshold  =    0;
  my Int $partial-increment  = 1000;
  my Int $full-path-number   =    0;
  my Int $complete-threshold =    0;
  my Int $complete-increment = commit-interval();

  $dbh.execute("begin transaction");
  my $list-macro = $dbh.prepare(q:to/SQL/);
  select num, path
  from   Macro_Paths
  where  map = ?
  order by num
  SQL
  for $list-macro.execute($map).allrows(:array-of-hash) -> $macro-path {
    my Int $num  = $macro-path<num>;
    my Str $path = $macro-path<path>;
    #say "generating macro-path $num for map $map: $path";
    my @to-do;
    my %partial = path      => '* →→ ' ~ $path
                , relations => %()
                , last      => '*'
                ;
    @to-do.push(%partial);
    #say @to-do.raku;
    while @to-do.elems > 0 {
      my     %old      = @to-do.pop;
      #   say %old;
      my Str $old-path = %old<path>; $old-path ~~  / '→→' \s* (\S+) /;
      my Str $old-reg  = $0.Str;
      my     %old-rel  = %old<relations>;
      #say $old-reg , "//", $old-path;
      if %old<path> ~~ / '→→' .* '→' / {

        # extending the partial path by one region
        for $extract-region-paths.execute($map, %old<last>, $old-reg).allrows(:array-of-hash) -> $reg-path {
          #say $reg-path;
          my Str $new-path = $old-path; $new-path ~~ s/'→' \s* $old-reg \s* / $reg-path<B.path> →/;
          my      %new-rel = %old-rel;  %new-rel{$old-reg} = $reg-path<B.num>;
          my %new = path      => $new-path
                  , relations => %new-rel
                  , last      => $reg-path<B.to_code>
                  ;
          @to-do.push(%new);
          ++$partial-paths-nb;
          if $partial-paths-nb ≥ $partial-threshold {
            say join(' ', DateTime.now.hh-mm-ss, $partial-paths-nb, $new-path);
            $partial-threshold += $partial-increment;
          }
        }

      }
      else {
        # processing the last region and storing into the database
        for $extract-last-region-paths.execute($map, %old<last>, $old-reg).allrows(:array-of-hash) -> $reg-path {
          my Str $new-path = $old-path; $new-path ~~ s/'→' \s* $old-reg \s* / $reg-path<B.path>/;
                                        $new-path ~~ s/'* → '//;
          my      %new-rel = %old-rel;  %new-rel{$old-reg} = $reg-path<B.num>;
          $new-path ~~ / ^ $<from>=(\S+) .* \s $<to>=(\S+) $/;
          ++$full-path-number;
          $sto-path.execute($map, 3, '', $full-path-number, $new-path, $<from>.Str, $<to>.Str, 0, $macro-path<num>);
          for %new-rel.kv -> $area, $num {
            $sto-relation.execute($map, $full-path-number, $area, $num);
          }
          if $full-path-number ≥ $complete-threshold {
            $dbh.execute("commit");
            $dbh.execute("begin transaction");
            say join(' ', DateTime.now.hh-mm-ss, $full-path-number, $new-path);
            $complete-threshold += $complete-increment;
          }
        }
      }
    }
  }
  $dbh.execute("commit");

  # Last step, the report
  $dbh.execute("begin transaction");
  if $full-path-number == 0 {
    $sto-mesg.execute($map, DateTime.now.Str, 'FUL2', '', 0, '');
  }
  else {
    $dbh.execute("update Maps set nb_full = ? where map = ?", $full-path-number, $map);
    $sto-mesg.execute($map, DateTime.now.Str, 'FUL3', '', $full-path-number, '');
  }
  $dbh.execute("commit");

}

=begin POD

=encoding utf8

=head1 NAME

gener2.raku -- generating the full Hamiltonian paths using macro-paths and regional paths

=head1 DESCRIPTION

This programme generates  the full Hamiltonian paths for  a map, using
already generated macro-paths and regional paths.

=head1 USAGE

  raku gener2.raku --map=frreg

=head1 PARAMETER

=head2 map

The code of the map, e.g. C<fr1970> or C<frreg>.

=head1 OTHER ELEMENTS

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<gener1.raku> and F<gener2.raku> programmes.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2022, Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
