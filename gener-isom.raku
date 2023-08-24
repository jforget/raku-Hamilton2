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

$dbh.execute("begin transaction");
$dbh.execute('delete from Isometries');
$dbh.execute('delete from Isom_Path');
$dbh.execute("commit");

my $sto-isom = $dbh.prepare(q:to/SQL/);
insert into Isometries (isometry, transform, length, recipr, involution)
       values          (?,        ?,         ?,      ?,      ?)
SQL

my $sto-path = $dbh.prepare(q:to/SQL/);
insert into Isom_Path (canonical_num, num, isometry, recipr)
       values         (?,             ?,   ?,        ?)
SQL
my Str $before       = "BCDFGHJKLMNPQRSTVWXZ";
my Str $after-lambda = "GBCDFKLMNPQZXWRSTVJH";
my Str $after-kappa  = "PCBZQRWXHGFDMLKJVTSN";
my Str $after-iota   = "CBGFDMLKJHXZQRWVTSNP";

multi sub infix:<↣> (Str $string, Str $isom where * eq 'Id') {
  return $string;
}

multi sub infix:<↣> (Str $string, Str $isom where * ~~ /^ <[ɩκλ]> * $/) {
  my Str $resul = $string;
  for $isom.comb -> $iso {
    given $iso {
      when 'λ' { $resul .= trans($before => $after-lambda); }
      when 'κ' { $resul .= trans($before => $after-kappa ); }
      when 'ɩ' { $resul .= trans($before => $after-iota  ); }
    }
  }
  return $resul;
}

my Str $back-lambda = $before; $back-lambda .= trans($after-lambda => $before);
my Str $back-kappa  = $before; $back-kappa  .= trans($after-kappa  => $before);
my Str $back-iota   = $before; $back-iota   .= trans($after-iota   => $before);

# we already know that iota is an involution, we check the programme agrees with that
if $back-iota ne $after-iota {
  say "problem with iota reciprocal: $back-iota ≠ $after-iota";
  exit(1);
}

my %seen = $before       => 'Id'
         , $after-lambda => 'λ'
         , $after-kappa  => 'κ'
         , $after-iota   => 'ɩ'
         ;
my @to-do = < λ κ ɩ >;

$dbh.execute("begin transaction");
$sto-isom.execute('Id', $before      , 0, 'Id', 1);
$sto-isom.execute('λ' , $after-lambda, 1, $back-lambda, -1);
$sto-isom.execute('κ' , $after-kappa , 1, $back-kappa , -1);
$sto-isom.execute('ɩ' , $after-iota  , 1, 'ɩ',  1);

while @to-do.elems > 0 {
  my Str $old-isom = @to-do.shift;
  for < λ κ ɩ > -> Str $next-isom {
    my Str $new-isom  = $old-isom ~ $next-isom;
    my Str $new-trans = $before ↣ $new-isom;
    # say join ' ', $new-trans, $new-isom;
    if %seen{$new-trans} {
      say join(' ', $new-trans, "duplicate", $new-isom, %seen{$new-trans});
    }
    else {
      %seen{$new-trans} = $new-isom;
      my Str $recipr = '';
      my Int $involution;
      my Str $backward = $before;
      $backward .= trans($new-trans => $before);
      if $backward eq $new-trans {
        $backward   = $new-isom;
        $involution = 1;
      }
      elsif %seen{$backward} {
        $backward   = %seen{$backward};
        $involution = 0;
      }
      else {
        $involution = -1;
      }

      $sto-isom.execute($new-isom, $new-trans, $new-isom.chars, $backward, $involution);
      @to-do.push($new-isom);
    }
  }
}

$dbh.execute(q:to/SQL/);
update Isometries as A
   set involution = 0
     , recipr     = (select B.isometry
                    from    Isometries B
                    where   B.transform = A.recipr
                    )
where A.involution = -1
SQL

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
SQL

for $sth-isometries.allrows(:array-of-hash) -> $isometry-rec {
  for @canonical-paths -> $canon-rec {
    my @actual-path = $sth-actual.execute($canon-rec<path> ↣ $isometry-rec<isometry>).row();
    $sto-path.execute($canon-rec<num>, @actual-path[0], $isometry-rec<isometry>, $isometry-rec<recipr>);
  }
}
$dbh.execute("commit");

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

Copyright (C) 2023, Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
