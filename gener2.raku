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

sub MAIN (
      Str  :$map             #= The code of the map
    ) {

  my %map = access-sql::read-map(~ $map);
  unless %map {
    die "Unkown map $map";
  }

  # Initial clean-up
  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths          where map = ? and level = 3", $map);
  $dbh.execute("delete from Path_Relations where map = ?"              , $map);
  $sto-mesg.execute($map, DateTime.now.Str, 'FUL1', '', 0-number, '');
  $dbh.execute("commit");

  # Last step, the report
  $dbh.execute("begin transaction");
  if $path-number == 0 {
    $sto-mesg.execute($map, DateTime.now.Str, 'FUL2', '', 0, '');
  }
  else {
    $sto-mesg.execute($map, DateTime.now.Str, 'FUL3', '', $path-number, '');
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
running the F<gener1.raku> programme.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2022, Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
