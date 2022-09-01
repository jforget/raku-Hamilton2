#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Serveur web permettant de consulter la base Hamilton.db des chemins doublement hamiltoniens
#     Web server to display the database storing doubly-Hamitonian paths
#     Copyright (C) 2022 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6.d;
use lib 'lib';
use Bailador;

use access-sql;
use map-list-page;
use full-map;
use macro-map;
use region-map;

my @languages = ( 'en', 'fr' );

get '/' => sub {
  redirect "/en/list/";
}

get '/:ln/list' => sub ($lng) {
  redirect "/$lng/list/";
}

get '/:ln/list/' => sub ($lng) {
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my @maps = access-sql::list-maps;
  return map-list-page::render(~ $lng, @maps);
}

get '/:ln/full-map/:map' => sub ($lng, $map) {
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my $mapcode = ~ $map;
  my %map     = access-sql::read-map($mapcode);
  my @areas   = access-sql::list-small-areas($mapcode);
  my @borders = access-sql::list-small-borders($mapcode);
  return full-map::render(~ $lng, $mapcode, %map, @areas, @borders);
}

get '/:ln/macro-map/:map' => sub ($lng_parm, $map_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-big-areas($map);
  my @borders = access-sql::list-big-borders($map);
  for @areas -> $area {
    $area<url> = "/$lng/region-map/$map/$area<code>";
  }
  return macro-map::render($lng, $map, %map, @areas, @borders);
}

get '/:ln/region-map/:map/:region' => sub ($lng_parm, $map_parm, $reg_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $region = ~ $reg_parm;
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-areas-in-region(   $map, $region);
  @areas.append(access-sql::list-neighbour-areas(   $map, $region));
  my @borders = access-sql::list-borders-for-region($map, $region);
  return region-map::render($lng, $map, $region, %map, @areas, @borders);
}

baile();


=begin POD

=encoding utf8

=head1 NAME

website.raku -- web server which gives a user-friendly view of the Hamilton database

=head1 DESCRIPTION

This program is a web server  which manages a website showing maps and
paths stored in the Hamilton database.

=head1 USAGE

On a command-line:

  raku website.raku

On a web browser:

  http://localhost:3000

To stop  the webserver, hit  C<Ctrl-C> on  the command line  where the
webserver was lauched.

=head1 COPYRIGHT and LICENSE

Copyright 2022, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
