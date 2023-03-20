#!/usr/bin/env raku
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Benchmark de la nouvelle base de données pour la deuxième tentative
#     Benchmarking the new database for the second attemps
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6;
use lib 'lib';
use DBIish;


my Str $orig-db = 'first-attempt/Hamilton.db';
my %tests =  'xn' => 'where exists (without index)'
           , 'xi' => 'where exists (with index)'
           , 'td' => 'table filled by select distinct'
           , 'tg' => 'table filled by select ... group by'
           , 'vd' => 'view defined by select distinct'
           , 'vg' => 'view defined by select ... group by'
	   ;

sub MAIN (
      Str  :$map     = 'fr2015' #= The code of the map
    , Str  :$current = 'HDF'    #= The code of the region within which regional paths are extracted
    , Str  :$next    = 'GES'    #= The code of the region to which the extracted regional paths must be linked
    ) {
  say "Benchmarking the new database using map $map and region $current, linking to $next";
  for %tests.keys.pick(6) -> $test {
    check($test, $map, $current, $next);
  }
}

sub check(Str $test, $map, $current, $next) {
  say '-' x 50;
  say "Checking ", %tests{$test};
  my @b;
  my @e;

  # step 1, copying the database
  my $new-db = "Hamilton-$test.db";
  run 'cp', $orig-db, $new-db;
  my $dbh = DBIish.connect('SQLite', database => $new-db);

  # step 2, altering the database
  @b[2] = DateTime.now;
  given $test {
    when 'xi' {
      create-index($dbh);
    }
    when 'td'|'tg' {
      create-table($dbh);
    }
    when 'vd' {
      create-vd($dbh);
    }
    when 'vg' {
      create-vg($dbh);
    }
  }
  @e[2] = DateTime.now;

  # step 3, filling the new table
  @b[3] = DateTime.now;
  given $test {
    when 'td' {
      fill-td($dbh, $map);
    }
    when 'tg' {
      fill-tg($dbh, $map);
    }
  }
  @e[3] = DateTime.now;

  # step 4, running the query
  @b[4] = DateTime.now;
  given $test {
    when 'xn'| 'xi' {
      run-xni($dbh, $map, $current, $next);
    }
    when 'td'|'tg'|'vd'|'vg' {
      run-dg($dbh, $map, $current, $next);
    }
  }
  @e[4] = DateTime.now;

  $dbh.dispose;

  # results
  for 2..4 -> $i {
    say "@b[$i] @e[$i] {sprintf("%.5f", @e[$i] - @b[$i])} step $i";
  }
}

sub create-index($dbh) {
  $dbh.execute(q:to/SQL/);
  create index Borders_1
  on Borders(map, level, from_code, upper_to)
  SQL
}

sub create-table($dbh) {
  $dbh.execute(q:to/SQL/);
  create table Egress (map       TEXT
                     , from_code TEXT
                     , upper_to  TEXT
                     );
  SQL
}

sub create-vd($dbh) {
  $dbh.execute(q:to/SQL/);
  create view Egress (map, from_code, upper_to)
  as select distinct  map, from_code, upper_to
     from   Borders
     where  level = 2
  SQL
}

sub create-vg($dbh) {
  $dbh.execute(q:to/SQL/);
  create view Egress (map, from_code, upper_to)
  as select map, from_code, upper_to
     from   Borders
     where  level = 2
     group by map, from_code, upper_to
  SQL
}

sub fill-td($dbh, Str $map) {
  $dbh.prepare(q:to/SQL/).execute($map);
  insert into Egress(map, from_code, upper_to)
      select distinct map, from_code, upper_to
      from   Small_Borders
      where  map = ?
  SQL
}

sub fill-tg($dbh, Str $map) {
  $dbh.prepare(q:to/SQL/).execute($map);
  insert into Egress(map, from_code, upper_to)
      select map, from_code, upper_to
      from   Small_Borders
      where  map = ?
      group by map, from_code, upper_to
  SQL
}

sub run-xni($dbh, Str $map, Str $current, Str $next) {
  my $sth  = $dbh.prepare(q:to/SQL/);
  select B.num     as num
       , B.path    as path
       , B.area    as area
       , B.to_code as to_code
  from Borders_With_Star A
  join Region_Paths B
     on  B.map       = A.map
     and B.area      = A.upper_to
     and B.from_code = A.to_code
  where A.map       = ?
  and   A.from_code = '*'
  and   A.upper_to  = ?
  and   exists (select 'x'
                from   Small_Borders C
                where  C.map    = B.map
                and    C.from_code = B.to_code
                and    C.upper_to  = ?
               )
  SQL
  my $cnt = 0;
  for $sth.execute($map, $current, $next).allrows(:array-of-hash) -> $x {
    ++$cnt;
  }
  say "counter $cnt";
}

sub run-dg($dbh, Str $map, Str $current, Str $next) {
  my $sth  = $dbh.prepare(q:to/SQL/);
  select B.num     as num
       , B.path    as path
       , B.area    as area
       , B.to_code as to_code
  from Borders_With_Star A
  join Region_Paths B
     on  B.map       = A.map
     and B.area      = A.upper_to
     and B.from_code = A.to_code
  join Egress C
     on  C.map       = B.map
     and C.from_code = B.to_code
  where A.map       = ?
  and   A.from_code = '*'
  and   A.upper_to  = ?
  and   C.upper_to  = ?
  SQL
  my $cnt = 0;
  for $sth.execute($map, $current, $next).allrows(:array-of-hash) -> $x {
    ++$cnt;
  }
  say "counter $cnt";
}

=begin POD

=encoding utf8

=head1 NAME

benchmark.raku -- benchmarking the new database for the second attemps

=head1 DESCRIPTION

This  programme  tries  several  solutions to  improve  the  main  SQL
statement used in the generation of full paths.

=head1 USAGE

  raku gener1.raku --map=fr2015 --current=HDF --next=GES

=head1 PARAMETERS

=head2 map

The code of the map, e.g. C<fr1970> or C<frreg>.

=head2 current

Code of the region within which the regional paths will be extracted.

=head2 next

Code of the region to which the extracted regional paths must be linked.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2023, Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
