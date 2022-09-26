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
use macro-path;
use region-map;

my @languages = ( 'en', 'fr' );

get '/' => sub {
  redirect "/en/list/";
}

get '/:ln/list' => sub ($lng) {
  redirect "/$lng/list/";
}

get '/:ln/list/' => sub ($lng_parm) {
  my Str $lng    = ~ $lng_parm;
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my @maps = access-sql::list-maps;
  return map-list-page::render($lng, @maps);
}

get '/:ln/full-map/:map' => sub ($lng_parm, $map_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-small-areas(  $map);
  my @borders = access-sql::list-small-borders($map);
  for @areas -> $area {
    $area<url> = "/$lng/region-map/$map/$area<upper>";
  }
  my @messages = access-sql::list-messages($map);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_, link => "/$lng/macro-path/$map/$_" ) } );

  @list-paths    = list-numbers(%map<nb_full>, 0);
  my @full-links = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_" ) } );

  return full-map::render($lng, $map, %map, @areas, @borders, messages => @messages);
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
  my @messages = access-sql::list-messages($map);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_, link => "/$lng/macro-path/$map/$_" ) } );

  @list-paths    = list-numbers(%map<nb_full>, 0);
  my @full-links = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_" ) } );

  return macro-map::render($lng, $map, %map, @areas, @borders
                          , messages    => @messages
                          , macro-links => @macro-links
                          , full-links  => @full-links
                          );
}

get '/:ln/region-map/:map/:region' => sub ($lng_parm, $map_parm, $reg_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $region = ~ $reg_parm;
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map        = access-sql::read-map($map);
  my @areas      = access-sql::list-areas-in-region(   $map, $region);
  my @neighbours = access-sql::list-neighbour-areas(   $map, $region);
  my @borders    = access-sql::list-borders-for-region($map, $region);
  @areas.append(@neighbours);
  for @areas -> $area {
    if $area<upper> eq $region {
      $area<url> = '';
    }
    else {
      $area<url> = "/$lng/region-map/$map/$area<upper>";
    }
  }
  my @messages = access-sql::list-regional-messages($map, $region);
  return region-map::render($lng, $map, $region, %map, @areas, @borders
                          , messages => @messages);
}

get '/:ln/macro-path/:map/:num' => sub ($lng_parm, $map_parm, $num_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Int $num    = + $num_parm;
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-big-areas($map);
  my @borders = access-sql::list-big-borders($map);
  for @areas -> $area {
    $area<url> = "/$lng/region-map/$map/$area<code>";
  }
  my %path     = access-sql::read-path($map, 1, '', $num);
  my @messages = access-sql::list-messages($map);
  my $max-path = access-sql::max-path-number($map, 1, '');
  my @list-paths = list-numbers($max-path, $num);
  my @links      = @list-paths.map( { %( txt => $_, link => "/$lng/macro-path/$map/$_" ) } );
  return macro-path::render($lng, $map, %map
                           , areas    => @areas
                           , borders  => @borders
                           , path     => %path
                           , messages => @messages
                           , links    => @links
                           );
}

baile();

sub list-numbers(Int $max, Int $center) {
  if $max ≤ 200 {
    return 1..$max;
  }
  my @possible = (-1, 1 X× 1..9 X× 1, 10, 100, 1000, 10000) «+» $center;
  return @possible.sort.grep( { 1 ≤ $_ ≤ $max } );
}

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
