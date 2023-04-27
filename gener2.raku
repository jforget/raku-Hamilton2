#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération des chemins hamiltoniens complets à partir des macro-chemins et des chemins régionaux génériques
#     Generating full Hamiltonian paths using macro-paths and generic regional paths
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
insert into Paths (map, level, area, num, path, from_code, to_code, cyclic, macro_num, generic_num, first_num, paths_nb)
       values     (?,   ?,     ?,    ?,   ?,    ?,         ?,       ?,      ?,	       0,	    ?,	       ?)
SQL

my $sto-relation = $dbh.prepare(q:to/SQL/);
insert into Path_Relations (map, full_num, area, region_num)
       values              (?,   ?,        ?,    ?)
SQL

my $upd-fruitless-b0 = $dbh.prepare(q:to/SQL/);
update Borders
set fruitless = 0
where map       = ?
and   level     = 1
SQL

my $upd-fruitless-b1 = $dbh.prepare(q:to/SQL/);
update Borders
set fruitless = 1
where map       = ?
and   level     = 1
and   from_code = ?
and   to_code   = ?
SQL

my $upd-fruitless-p0 = $dbh.prepare(q:to/SQL/);
update Paths
set fruitless        = 0
  , fruitless_reason = ''
where map       = ?
and   level     = 1
SQL

my $upd-fruitless-p1 = $dbh.prepare(q:to/SQL/);
update Paths
set fruitless        = 1
  , fruitless_reason = ?
where map       = ?
and   level     = 1
and   fruitless = 0
and   path      like ?
SQL

my $upd-fruitless-p2 = $dbh.prepare(q:to/SQL/);
update Paths
set fruitless_reason = fruitless_reason || ?
where map       = ?
and   level     = 1
and   fruitless = 1
and   path      like ?
SQL

my $extract-region-paths  = $dbh.prepare(q:to/SQL/);
select B.num      as num
     , B.path     as path
     , B.area     as area
     , B.to_code  as to_code
     , B.paths_nb as paths_nb
from Borders_With_Star A
join Generic_Region_Paths B
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
join Exit_Borders C
   on  C.map       = B.map
   and C.from_code = B.to_code
where A.map       = ?
and   A.from_code = ?
and   A.upper_to  = ?
and   C.upper_to  = ?
order by B.num desc
SQL

my $extract-last-region-paths  = $dbh.prepare(q:to/SQL/);
select B.num      as num
     , B.path     as path
     , B.area     as area
     , B.to_code  as to_code
     , B.paths_nb as paths_nb
from Borders_With_Star A
join Generic_Region_Paths B
   on  B.map       = A.map
   and B.area      = A.upper_to
   and B.from_code = A.to_code
where A.map       = ?
and   A.from_code = ?
and   A.upper_to  = ?
order by B.num desc
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
  my Int $max-macro = %map<nb_macro>;

  # Initial clean-up
  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths          where map = ? and level = 3"          , $map);
  $dbh.execute("delete from Path_Relations where map = ?"                        , $map);
  $dbh.execute("delete from Messages       where map = ? and errcode like 'FUL_'", $map);
  $sto-mesg.execute($map, DateTime.now.Str, 'FUL1', '', 0, '');
  $dbh.execute("commit");
  my Int $path-number = 0;

  # fruitless macro-paths
  $upd-fruitless-p0.execute($map);
  $upd-fruitless-b0.execute($map);
  my $extract-fruitless = $dbh.prepare(q:to/SQL/);
  select B.map, B.upper_from as upper_from, B.upper_to as upper_to, count(P.map) as nb
  from Small_Borders B
  left join Region_Paths P
    on  P.map       = B.map
    and P.from_code = B.to_code
  where B.upper_from != B.upper_to
  and B.map = ?
  group by B.map, B.upper_from, B.upper_to
  SQL
  for $extract-fruitless.execute($map).allrows(:array-of-hash) -> $border {
    if $border<nb> == 0 {
      my Str $border-str = "$border<upper_from> → $border<upper_to>";
      $upd-fruitless-p2.execute(", " ~ $border-str, $map, '%' ~  $border-str ~ '%');
      $upd-fruitless-p1.execute(       $border-str, $map, '%' ~  $border-str ~ '%');
      $upd-fruitless-b1.execute($map, $border<upper_from>, $border<upper_to>);

      $sto-mesg.execute($map, DateTime.now.Str, 'FUL4', '', 0, $border-str);
      say "{DateTime.now.hh-mm-ss} Fruitless border: $border-str";

      $border-str = "$border<upper_to> → $border<upper_from>";
      $upd-fruitless-p2.execute(", " ~ $border-str, $map, '%' ~  $border-str ~ '%');
      $upd-fruitless-p1.execute(       $border-str, $map, '%' ~  $border-str ~ '%');
      $upd-fruitless-b1.execute($map, $border<upper_to>, $border<upper_from>);
    }
  }
  my $counting = $dbh.prepare(q:to/SQL/);
  select count(*) as nb
  from   Macro_Paths
  where  map       = ?
  and    fruitless = 1
  SQL
  my Int @nb;
  @nb = $counting.execute($map).row();
  $sto-mesg.execute($map, DateTime.now.Str, 'FUL5', '', @nb[0], '');
  say "{DateTime.now.hh-mm-ss} Fruitless macro-paths: @nb[0]";

  my Int $partial-paths-nb   =    0;
  my Int $partial-threshold  =    0;
  my Int $partial-increment  = 1000;
  my Int $full-path-number   =    0;
  my Int $complete-threshold =    0;
  my Int $complete-increment = commit-interval();
  my Int $max-to-do          = 0;
  my Int $num                = 0;
  my Int $first-num          = 1;
  my Int $to-do-nb;
  sub aff-stat {
    say "{DateTime.now.hh-mm-ss} macro number $num / $max-macro, generic paths $full-path-number, specific paths {$first-num - 1}, partial paths $partial-paths-nb (to-do list $to-do-nb / $max-to-do)";
  }

  $dbh.execute("begin transaction");
  my $list-macro = $dbh.prepare(q:to/SQL/);
  select num, path
  from   Macro_Paths
  where  map       = ?
  and    fruitless = 0
  order by num
  SQL
  for $list-macro.execute($map).allrows(:array-of-hash) -> $macro-path {
    $num  = $macro-path<num>;
    my Str $path = $macro-path<path>;

    my @to-do;
    my %partial = path      => '* →→ ' ~ $path
                , relations => %()
                , last      => '*'
                , paths_nb  => 1
                ;
    @to-do.push(%partial);
    #say @to-do.raku;
    while @to-do.elems > 0 {
      $to-do-nb = @to-do.elems;
      if $max-to-do < $to-do-nb {
        $max-to-do = $to-do-nb;
      }
      my     %old      = @to-do.pop;
      #   say %old;
      my Str $old-path = %old<path>; $old-path ~~  / '→→' \s* (\S+) /;
      my Str $old-reg  = $0.Str;
      my     %old-rel  = %old<relations>;
      #say $old-reg , "//", $old-path;
      if %old<path> ~~ / '→→' .* '→' / {

        # Finding the next region after the soon-replaced region
        %old<path> ~~ / '→→' .*? '→' \s+ (\S*) /;
        my Str $next-reg = $0.Str;

        # extending the partial path by one region
        for $extract-region-paths.execute($map, %old<last>, $old-reg, $next-reg).allrows(:array-of-hash) -> $reg-path {
          #say $reg-path;
          my Str $new-path = $old-path; $new-path ~~ s/'→' \s* $old-reg \s* / $reg-path<path> →/;
          my      %new-rel = %old-rel;  %new-rel{$old-reg} = $reg-path<num>;
          my %new = path      => $new-path
                  , relations => %new-rel
                  , last      => $reg-path<to_code>
                  , paths_nb  => %old<paths_nb> × $reg-path<paths_nb>
                  ;
          @to-do.push(%new);
          ++$partial-paths-nb;
          $to-do-nb = @to-do.elems;
          if $max-to-do < $to-do-nb {
            $max-to-do = $to-do-nb;
          }
          if $partial-paths-nb ≥ $partial-threshold {
            aff-stat();
            $partial-threshold += $partial-increment;
          }
        }

      }
      else {
        # processing the last region and storing into the database
        for $extract-last-region-paths.execute($map, %old<last>, $old-reg).allrows(:array-of-hash) -> $reg-path {
          my Str $new-path = $old-path; $new-path ~~ s/'→' \s* $old-reg \s* / $reg-path<path>/;
                                        $new-path ~~ s/'* → '//;
          my      %new-rel = %old-rel;  %new-rel{$old-reg} = $reg-path<num>;
          $new-path ~~ / ^ $<from>=(\S+) .* \s $<to>=(\S+) $/;
          ++$full-path-number;
          my $result = $sth-check-cyclic.execute($map, $<from>.Str, $<to>.Str).row;
          my Int $cyclic;
          if $result eq 'X' {
            $cyclic = 1;
          }
          else {
            $cyclic = 0;
          }
          $sto-path.execute($map, 3, '', $full-path-number, $new-path, $<from>.Str, $<to>.Str, $cyclic, $macro-path<num>, $first-num, %old<paths_nb> × $reg-path<paths_nb>);
 	  $first-num += %old<paths_nb> × $reg-path<paths_nb>;
          for %new-rel.kv -> $area, $num {
            $sto-relation.execute($map, $full-path-number, $area, $num);
          }
          if $full-path-number ≥ $complete-threshold {
            $dbh.execute("commit");
            $dbh.execute("begin transaction");
            aff-stat();
            $complete-threshold += $complete-increment;
          }
        }
      }
    }
  }
  $dbh.execute("commit");
  $to-do-nb = 0;
  aff-stat();

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
