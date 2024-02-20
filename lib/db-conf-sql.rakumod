# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Valeurs codées en dur pour la base de données Hamilton
#     Hard-coded values for the Hamilton database
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;

unit module db-conf-sql;

my Str $dbname = '/home/jf/Documents/prog/rakudo/raku-Hamilton2/Hamilton.db';
my Int $commit-interval = 100;

sub dbname is export {
  return $dbname;
}

sub commit-interval is export {
  return $commit-interval;
}

sub picture-width is export {
  return 800;
}

sub picture-height is export {
  return 800;
}

sub sample-size is export {
  return 10;
}

=begin POD

=encoding utf8

=head1 NAME

db-conf-sql.rakumod -- hard-coded values for the Hamilton database

=head1 DESCRIPTION

This module  gives hard-coded  values related  to the  SQLite Hamilton
database: the  database pathname, and  the commit interval  (number of
inserts  /  updates  betwee  two   successive  commits).  It  is  used
internally   by   C<init-fr.raku>,   C<gener1.raku>,   C<gener2.raku>,
C<website.raku> and C<access-sql.rakumod>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, 2023, 2024 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
