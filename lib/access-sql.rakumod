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
  my $sth = $dbh.prepare("select map, name from Maps");
  my @maps = $sth.execute().allrows;
  #say @maps;
  return @maps;
}

our sub read-map(Str $map) {
  my $sth = $dbh.prepare("select map, name from Maps where map = ?");
  my %val = $sth.execute($map).row(:hash);
  return %val;
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
