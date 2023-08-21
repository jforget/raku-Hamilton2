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

$dbh.execute('delete from Isometries');
$dbh.execute('delete from Isom_Path');

my $sto-isom = $dbh.prepare(q:to/SQL/);
insert into Isometries (isometry, transform, length, recipr, invol)
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

multi sub infix:<→> (Str $string, Str $isom where * eq 'Id') {
  return $string;
}

multi sub infix:<→> (Str $string, Str $isom where * ~~ /^ <[ɩκλ]> * $/) {
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

my %seen = $before       => 'Id'
         , $after-lambda => 'λ'
         , $after-kappa  => 'κ'
         , $after-iota   => 'ɩ'
         ;
my @to-do = < λ κ ɩ >;

$sto-isom.execute('Id', $before      , 0, '', 0);
$sto-isom.execute('λ' , $after-lambda, 1, '', 0);
$sto-isom.execute('κ' , $after-kappa , 1, '', 0);
$sto-isom.execute('ɩ' , $after-iota  , 1, '', 0);

while @to-do.elems > 0 {
  my Str $old-isom = @to-do.shift;
  for < λ κ ɩ > -> Str $next-isom {
    my Str $new-isom  = $old-isom ~ $next-isom;
    my Str $new-trans = $before → $new-isom;
    # say join ' ', $new-trans, $new-isom;
    if %seen{$new-trans} {
      say join(' ', $new-trans, "duplicate", $new-isom, %seen{$new-trans});
    }
    else {
      %seen{$new-trans} = $new-isom;
      $sto-isom.execute($new-isom, $new-trans, $new-isom.chars, '', 0);
      @to-do.push($new-isom);
    }
  }
}

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
