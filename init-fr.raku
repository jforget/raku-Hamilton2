#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Initialisation des cartes de France avec les départements, les régions de 2015 et les régions de 1970
#     Initialising the maps of France with departments, Y2015 regions and Y1970 regions.
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;
use db-conf-sql;


my $dbh = DBIish.connect('SQLite', database => dbname());

$dbh.execute(q:to/SQL/);
delete from Maps where map in ('fr1970', 'fr2015', 'frreg');
SQL

$dbh.execute(q:to/SQL/);
delete from Areas where map in ('fr1970', 'fr2015', 'frreg');
SQL

$dbh.execute(q:to/SQL/);
delete from Borders where map in ('fr1970', 'fr2015', 'frreg');
SQL

$dbh.execute(q:to/SQL/);
insert into Maps values ('fr1970', 'Départements dans les régions de 1970');
SQL

$dbh.execute(q:to/SQL/);
insert into Maps values ('fr2015', 'Départements dans les régions de 2015');
SQL

$dbh.execute(q:to/SQL/);
insert into Maps values ('frreg',  'Régions de 1970 dans les régions de 2015');
SQL

=begin POD

=encoding utf8

=head1 NAME

init-fr.raku -- initialising the region+department maps of France

=head1 DESCRIPTION

This programme  reads a file  listing all departments and  regions for
France and  store them  in the database.  Tables filled  are: C<Maps>,
C<Regions> and C<Borders>.

=head1 USAGE

  sqlite3 Hamilton.db < cr.sql
  raku init-fr.raku

=head2 Parameters

None.

=head2 Database Configuration

The   filename  of   the  SQLite   database  is   hard-coded  in   the
F<lib/db-conf-sql.rakumod> file.  Be sure to update  this value before
running the F<init-fr.raku> program.

=head1 COPYRIGHT and LICENCE

Copyright (C) 2022, Jean Forget, all rights reserved

This  program is  published under  the  same conditions  as Raku:  the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
