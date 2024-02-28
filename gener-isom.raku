#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération des isométries pour le jeu icosien
#     Generating isometries for the icosian game
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

my $sto-isom = $dbh.prepare(q:to/SQL/);
insert into Isometries (map, isometry, transform, length, recipr, involution)
       values          (?  , ?,        ?,         ?,      ?,      ?)
SQL

my $sto-path = $dbh.prepare(q:to/SQL/);
insert into Isom_Path (map, canonical_num, num, isometry, recipr)
       values         (?  , ?,             ?,   ?,        ?)
SQL

sub maj-isometries(Str $map) {

  $dbh.execute("begin transaction");
  $dbh.execute('delete from Isometries where map = ?', $map);
  $dbh.execute('delete from Isom_Path  where map = ?', $map);
  $dbh.execute("commit");
my Str $before       = "BCDFGHJKLMNPQRSTVWXZ";
my Str $after-lambda = "GBCDFKLMNPQZXWRSTVJH";
my Str $after-kappa  = "PCBZQRWXHGFDMLKJVTSN";
my Str $after-iota   = "CBGFDMLKJHXZQRWVTSNP";

my @before;
my %before; # Gives the 0..^20 index of a letter
my @transf-lambda; # For a before rotation index, gives the corresponding after rotation index
my @transf-kappa ; # For a before rotation index, gives the corresponding after rotation index
my @transf-iota  ; # For a before symmetry index, gives the corresponding after symmetry index
my %trans;

for $before.comb.kv -> $i, $c {
  @before[$i] = $c;
  %before{$c} = $i;
}
for $after-lambda.comb.kv -> $i, $c {
  @transf-lambda[%before{$c}] = $i;
}
for $after-kappa.comb.kv -> $i, $c {
  @transf-kappa[%before{$c}] = $i;
}
for $after-iota.comb.kv -> $i, $c {
  @transf-iota[%before{$c}] = $i;
}

multi sub transform(Str $isom where * eq 'Id') {
  return $before;
}

multi sub transform(Str $isom where * ~~ /^ <[ɩκλ]> * $/) {
  my @list = @before;
  for $isom.comb -> $iso {
    given $iso {
      when 'λ' { @list[@transf-lambda] = @list; }
      when 'κ' { @list[@transf-kappa ] = @list; }
      when 'ɩ' { @list[@transf-iota  ] = @list; }
    }
  }
  return @list.join;
}

multi sub infix:<↣> (Str $string, Str $isom where * eq 'Id') {
  return $string;
}

multi sub infix:<↣> (Str $string, Str $isom where * ~~ /^ <[ɩκλ]> * $/) {
  my Str $resul = $string.trans($before => %trans{$isom});
  return $resul;
}

my Str $back-lambda = $before; $back-lambda .= trans($after-lambda => $before);
my Str $back-kappa  = $before; $back-kappa  .= trans($after-kappa  => $before);
my Str $back-iota   = $before; $back-iota   .= trans($after-iota   => $before);

my %seen = $before       => 'Id'
         , $after-lambda => 'λ'
         , $after-kappa  => 'κ'
         , $after-iota   => 'ɩ'
         ;
%trans = %seen.invert;
my @to-do = < λ κ ɩ >;

  $dbh.execute("begin transaction");
  $sto-isom.execute($map, 'Id', $before      , 0, $before     , -1);
  $sto-isom.execute($map, 'λ' , $after-lambda, 1, $back-lambda, -1);
  $sto-isom.execute($map, 'κ' , $after-kappa , 1, $back-kappa , -1);
  $sto-isom.execute($map, 'ɩ' , $after-iota  , 1, $back-iota  , -1);

while @to-do.elems > 0 {
  my Str $old-isom = @to-do.shift;
  for < λ κ ɩ > -> Str $next-isom {
    my Str $new-isom  = $old-isom ~ $next-isom;
    my Str $new-trans = transform($new-isom);
    # say join ' ', $new-trans, $new-isom;
    if %seen{$new-trans} {
      say join(' ', $new-trans, "duplicate", $new-isom, %seen{$new-trans});
    }
    else {
      %seen{$new-trans} = $new-isom;
      %trans{$new-isom} = $new-trans;
      my Str $recipr = $before.trans($new-trans => $before);
      $sto-isom.execute($map, $new-isom, $new-trans, $new-isom.chars, $recipr, -1);
      @to-do.push($new-isom);
    }
  }
}

$dbh.execute("commit");
$dbh.execute("begin transaction");

my $sth-canonical-paths = $dbh.execute(q:to/SQL/);
select   num, path
from     Region_Paths
where    map = 'ico'
and      path like 'B → C → D → %'
order by num
SQL
my @canonical-paths = $sth-canonical-paths.allrows(:array-of-hash);

my $sth-actual = $dbh.prepare(q:to/SQL/);
select   num
from     Region_Paths
where    map  = 'ico'
and      path = ?
SQL

my $sth-isometries = $dbh.execute(q:to/SQL/);
select   isometry, transform, recipr
from     Isometries
where    map = 'ico'
SQL

for $sth-isometries.allrows(:array-of-hash) -> $isometry-rec {
  for @canonical-paths -> $canon-rec {
    my @actual-path = $sth-actual.execute($canon-rec<path> ↣ $isometry-rec<isometry>).row();
    $sto-path.execute($map, $canon-rec<num>, @actual-path[0], $isometry-rec<isometry>, $isometry-rec<recipr>);
  }
}
$dbh.execute(q:to/SQL/, $map);
update Maps
set    with_isom = 1
where  map = ?
SQL
$dbh.execute("commit");

}
maj-isometries('ico');

=begin POD

=encoding utf8

=head1 NAME

gener-isom.raku -- generating the isometries for the icosian game

=head1 DESCRIPTION

This programme  generates the isometries for the icosian game
and the relations between canonical paths and other paths.

=head1 USAGE

  raku gener-isom.raku

=head1 PARAMETERS

None.

=head1 OTHER ELEMENTS

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<gener1.raku> programme.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2023, 2024 Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
