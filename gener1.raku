#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération des macro-chemins hamiltoniens et des chemins hamiltoniens régionaux
#     Genetating macro-paths and regional paths
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
insert into Messages (map, dh, errcode, area, nb)
       values        (?,   ?,  ?,       ?,    ?)
SQL

sub MAIN (
      Str  :$map             #= The code of the map
    , Bool :$macro = False   #= True to generate the macro-paths, else False
    , Str :$regions = ''     #= Comma-delimited list of region codes, e.g. --regions=NOR,CEN,HDF
    ) {

  my %map = access-sql::read-map(~ $map);
  unless %map {
    die "Unkown map $map";
  }

  my Str @regions = $regions.split(',');
  my Str @unknown-regions;
  if $regions ne '' {
    for @regions -> Str $region {
      my $result = $dbh.execute("select 'X' from Big_Areas where map = ? and code = ?", $map, $region).row;
      if $result ne 'X' {
        push @unknown-regions, $region;
      }
    }
  }
  if @unknown-regions {
    die "Unknown regions: ", @unknown-regions.join(', ');
  }

  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths          where map = ? and level = 3", $map);
  $dbh.execute("delete from Path_Relations where map = ?"              , $map);
  $dbh.execute("commit");

  if $macro or $regions eq '' {
    say "generating macro-paths for $map";
    generate($map, 1, '', 'MAC');
  }
  if ! $macro && $regions eq '' {
    say "generating regional paths for all regions of $map";
    for access-sql::list-big-areas($map) -> $region {
      say "generating regional paths for region $region<code> of $map";
      generate($map, 2, $region<code>, 'REG');
    }
  }
  if $regions ne '' {
    for @regions -> Str $region {
      say "generating regional paths for region $region of $map";
      generate($map, 2, $region, 'REG');
    }
  }
}

sub generate(Str $map, Int $level, Str $region, Str $prefix) {
  $dbh.execute("begin transaction");
  $dbh.execute("delete from Paths    where map = ? and level = ? and area = ?", $map, $level, $region);
  $dbh.execute("delete from Messages where map = ? and area = ? and errcode like ?", $map, $region, $prefix ~ '%');
  $sto-mesg.execute($map, DateTime.now.Str, $prefix ~ '1', $region, 0);
  $dbh.execute("commit");

}


=begin POD

=encoding utf8

=head1 NAME

gener1.raku -- generating the macro-paths and regional paths for a region

=head1 DESCRIPTION

This programme  generates some or  all macro-paths and  regional paths
for a map.

=head1 USAGE

  raku gener1.raku --map=frreg --macro --regions=NOR,HDF

=head1 PARAMETERS

=head2 map

The code of the map, e.g. C<fr1970> or C<frreg>.

=head2 macro

Boolean parameter to run or to bypass macro-path generation.

=head2 regions

String giving the codes of the regions that will be processed.
The region codes are separated by commas (with no spaces).

=head2 Special case

If both C<macro> and C<regions> parameters are missing (or C<False> in
the case  of C<macro>),  then the  generation programme  generates all
macro-paths and all regional paths for all regions of the map.

On the other hand, the C<map> parameter is mandatory.

=head2 Parameter Summary

If you want to generate only macro-paths without any regional paths:

  raku gener1.raku --map=frreg --macro

If you want to generate macro-paths and some regional paths

  raku gener1.raku --map=frreg --macro --regions=NOR,HDF

If you want to generate macro-paths and regional paths for all regions

  raku gener1.raku --map=frreg

If you want to generate neither macro-paths nor regional paths.

Why  would you  do that?  You  just type  nothing. You  do not  launch
C<gener1.raku>.

If you want to generate some regional paths but no macro-paths

  raku gener1.raku --map=frreg --regions=NOR,HDF

If you want to generate regional paths for all regions, but no macro-paths.

Sorry, that is not possible.

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
