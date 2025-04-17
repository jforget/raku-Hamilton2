#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Serveur web permettant de consulter la base Hamilton.db des chemins doublement hamiltoniens
#     Web server to display the database storing doubly-Hamitonian paths
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6.d;
use lib 'lib';
use Cro::HTTP::Router;
use Cro::HTTP::Server;

use access-sql;
use map-list-page;
use map;
use common;
use macro-path;
use region-path;
use full-path;
#use Hamilton-stat;
#use region-with-full-path;
#use deriv-ico-path;
#use shortest-path-stat;

my @languages = ( 'en', 'fr' );

my $application = all-routes;

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<localhost>, :port<10000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}

sub all-routes {
  return route {
    get -> {
      redirect :permanent, 'en/list';
    }
    get -> Str $lng, 'list' {
      if $lng !~~ /^ @languages $/ {
        content 'text/html', slurp('html/unknown-language.html');
      }
      else {
        my @maps = access-sql::list-maps;
        content 'text/html', map-list-page::render($lng, @maps);
      }
    }
    get -> Str $lng, 'full-map', Str $map, :%query-params {
      if $lng !~~ /^ @languages $/ {
        content 'text/html', slurp('html/unknown-language.html');
      }
      my $query-string = query-from-params(%query-params);
      my %map     = access-sql::read-map($map);
      my @areas   = access-sql::list-small-areas(  $map);
      my @borders = access-sql::list-small-borders($map);
      for @areas -> $area {
        $area<url> = "/$lng/region-map/$map/$area<upper>$query-string";
      }
      my @messages = access-sql::list-messages($map);

      my @list-paths  = list-numbers(%map<nb_macro>, 0);
      my @macro-links = @list-paths.map( { %( txt  => $_
                                            , link => "/$lng/macro-path/$map/$_$query-string"
                                            , bold => access-sql::bold-macro-path($map, $_)
                                            ) } );

      @list-paths     = list-numbers(%map<nb_full>, 0);
      my @full-links  = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
      my @canon-links = access-sql::list-ico-paths-for-isom($map, 'Id');

      content 'text/html'
           , map::render($lng, $map
                       , map          => %map
                       , region       => %()
                       , areas        => @areas
                       , borders      => @borders
                       , messages     => @messages
                       , macro-links  => @macro-links
                       , full-links   => @full-links
                       , region-links => ()
                       , canon-links  => @canon-links
                       , query-params => %query-params
                       , query-string => $query-string
                       );
    }
    get -> Str $lng, 'macro-map', Str $map, :%query-params {
      if $lng !~~ /^ @languages $/ {
        content 'text/html', slurp('html/unknown-language.html');
      }
      my $query-string = query-from-params(%query-params);
      my %map     = access-sql::read-map($map);
      my @areas   = access-sql::list-big-areas($map);
      my @borders = access-sql::list-big-borders($map);
      for @areas -> $area {
        $area<url> = "/$lng/region-map/$map/$area<code>$query-string";
      }
      my @messages = access-sql::list-messages($map);

      my @list-paths  = list-numbers(%map<nb_macro>, 0);
      my @macro-links = @list-paths.map( { %( txt => $_
                                            , link => "/$lng/macro-path/$map/$_$query-string"
                                            , bold => access-sql::bold-macro-path($map, $_)
                                            ) } );

      @list-paths    = list-numbers(%map<nb_full>, 0);
      my @full-links = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
      my @canon-links  = access-sql::list-ico-paths-for-isom($map, 'Id');

      content 'text/html'
           , map::render($lng, $map
                       , map          => %map
                       , region       => %()
                       , areas        => @areas
                       , borders      => @borders
                       , messages     => @messages
                       , macro-links  => @macro-links
                       , full-links   => @full-links
                       , region-links => ()
                       , canon-links  => @canon-links
                       , query-params => %query-params
                       , query-string => $query-string
                       );
    }
    get -> Str $lng, 'region-map', Str $map, Str $region, :%query-params {
      if $lng !~~ /^ @languages $/ {
        content 'text/html', slurp('html/unknown-language.html');
      }
      my $query-string = query-from-params(%query-params);
      my %map        = access-sql::read-map($map);
      my %region     = access-sql::read-region(            $map, $region);
      my @areas      = access-sql::list-areas-in-region(   $map, $region);
      my @neighbours = access-sql::list-neighbour-areas(   $map, $region);
      my @borders    = access-sql::list-borders-for-region($map, $region);

      @areas.append(@neighbours);
      for @areas -> $area {
        if $area<upper> eq $region {
          $area<url> = '';
        }
        else {
          $area<url> = "/$lng/region-map/$map/$area<upper>$query-string";
        }
      }

      my @list-paths  = list-numbers(%map<nb_macro>, 0);
      my @macro-links = @list-paths.map( { %( txt  => $_
                                            , link => "/$lng/macro-path/$map/$_$query-string"
                                            , bold => access-sql::bold-macro-path($map, $_)
                                            ) } );

      @list-paths     = list-numbers(%map<nb_full>, 0);
      my @full-links  = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
      @list-paths     = list-numbers(%region<nb_region_paths>, 0);
      my @path-links  = @list-paths.map( { %( txt => $_, link => "/$lng/region-path/$map/$region/$_$query-string" ) } );
      my @canon-links = access-sql::list-ico-paths-for-isom($map, 'Id');

      my @messages = access-sql::list-regional-messages($map, $region);
      content 'text/html'
           , map::render($lng, $map
                       , map          => %map
                       , region       => %region
                       , areas        => @areas
                       , borders      => @borders
                       , messages     => @messages
                       , macro-links  => @macro-links
                       , full-links   => @full-links
                       , region-links => @path-links
                       , canon-links  => @canon-links
                       , query-params => %query-params
                       , query-string => $query-string
                       );
    }
    get -> Str $lng, 'macro-path', Str $map, Int $num, :%query-params {
      if $lng !~~ /^ @languages $/ {
        content 'text/html', slurp('html/unknown-language.html');
      }
      my $query-string = query-from-params(%query-params);
      my %map     = access-sql::read-map($map);
      my @areas   = access-sql::list-big-areas($map);
      my @borders = access-sql::list-big-borders($map);
      for @areas -> $area {
        $area<url> = "/$lng/region-map/$map/$area<code>$query-string";
      }
      my %path     = access-sql::read-path($map, 1, '', $num);
      my @messages = access-sql::list-messages($map);

      my @list-paths = list-numbers(%map<nb_macro>, $num);
      my @macro-links = @list-paths.map( { %( txt => $_
                                            , link => "/$lng/macro-path/$map/$_$query-string"
                                            , bold => access-sql::bold-macro-path($map, $_)
                                            ) } );

      my @full-interval = access-sql::full-path-interval($map, $num);
      my @full-links = ();
      if @full-interval[0] != 0 {
        my @nums = list-numbers(@full-interval[1], @full-interval[0] - 1).grep({ $_ ≥ @full-interval[0] });
        @full-links = @nums.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) });
      }

      my @ico-links = access-sql::list-ico-paths-for-isom($map, 'Id');
      my %reverse-link = access-sql::read-path-by-path($map, 1, '', common::rev-path(%path<path>));
      %reverse-link<link> = "/$lng/macro-path/$map/%reverse-link<num>$query-string";

      content 'text/html'
           , macro-path::render($lng, $map, %map
                               , areas          => @areas
                               , borders        => @borders
                               , path           => %path
                               , messages       => @messages
                               , macro-links    => @macro-links
                               , full-links     => @full-links
                               , ico-links      => @ico-links
                               , reverse-link   => %reverse-link
                               , query-params   => %query-params
                               , query-string   => $query-string
                               );
    }
    get -> Str $lng, 'region-path', Str $map, Str $region, Int $num, :%query-params {
      if $lng !~~ /^ @languages $/ {
        content 'text/html', slurp('html/unknown-language.html');
      }
      my $query-string = query-from-params(%query-params);
      my %map     = access-sql::read-map($map);
      my %region  = access-sql::read-region($map, $region);

      my @areas      = access-sql::list-areas-in-region(   $map, $region);
      my @neighbours = access-sql::list-neighbour-areas(   $map, $region);
      my @borders    = access-sql::list-borders-for-region($map, $region);
      @areas.append(@neighbours);
      for @areas -> $area {
        if $area<upper> eq $region {
          $area<url> = '';
        }
        else {
          $area<url> = "/$lng/region-map/$map/$area<upper>$query-string";
        }
      }
      my %path     = access-sql::read-path($map, 2, $region, $num);
      my @messages = access-sql::list-regional-messages($map, $region);

      my @list-paths = list-numbers(%region<nb_region_paths>, $num);
      my @links      = @list-paths.map( { %( txt => $_, link => "/$lng/region-path/$map/$region/$_$query-string" ) } );

      my @full-numbers = access-sql::path-relations($map, $region, $num);
      my @full-links;
      for @full-numbers.kv -> $i, $num {
        push @full-links, %(txt => "{$i + 1}:$num", link => "http:/$lng/full-path/$map/$num$query-string");
      }
      my @indices    = list-numbers(@full-numbers.elems, $num) «-» 1;
      my @ico-links  = access-sql::list-ico-paths-for-isom($map, 'Id');
      my %reverse-link = access-sql::read-path-by-path($map, 2, $region, common::rev-path(%path<path>));
      %reverse-link<link> = "/$lng/region-path/$map/$region/%reverse-link<num>$query-string";

      content 'text/html'
           , region-path::render(lang           => $lng
                               , mapcode        => $map
                               , map            => %map
                               , region         => %region
                               , areas          => @areas
                               , borders        => @borders
                               , path           => %path
                               , messages       => @messages
                               , rpath-links    => @links
                               , fpath-links    => @full-links[@indices]
                               , ico-links      => @ico-links
                               , reverse-link   => %reverse-link
                               , query-params   => %query-params
                               , query-string   => $query-string
                               );
    }
    get -> Str $lng, 'full-path', Str $map, Int $num, :%query-params {
      if $lng !~~ /^ @languages $/ {
        content 'text/html', slurp('html/unknown-language.html');
      }
      my $query-string = query-from-params(%query-params);
      my %map     = access-sql::read-map($map);
      my @areas   = access-sql::list-small-areas($map);
      my @borders = access-sql::list-small-borders($map);
      for @areas -> $area {
        $area<url> = "/$lng/region-with-full-path/$map/$area<upper>/$num$query-string";
      }
      my %path;
      if %map<specific_paths> == 1 {
        %path        = access-sql::read-path($map, 3, '', $num);
      }
      else {
        %path        = access-sql::read-specific-path($map, $num);
      }
      my @messages   = access-sql::list-messages($map);
      my @list-paths = list-numbers(%map<nb_full>, $num);
      my @links      = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
      my @ico-links  = access-sql::list-ico-paths-for-isom($map, 'Id');

      content 'text/html'
           , full-path::render($lng, $map, %map
                              , areas        => @areas
                              , borders      => @borders
                              , path         => %path
                              , messages     => @messages
                              , links        => @links
                              , ico-links    => @ico-links
                              , query-params => %query-params
                              , query-string => $query-string
                              );
    }
  }
}

sub list-numbers(Int $max, Int $center) {
  if $max ≤ 200 {
    return 1..$max;
  }
  my @pow10 = 1, 10, 100;
  my $pow10 = 1000;
  while $pow10 ≤ $max {
    push @pow10, $pow10;
    $pow10 ×= 10;
  }
  my @possible = (-1, 1 X× 1..9 X× @pow10) «+» $center;
  return @possible.sort.grep( { 1 ≤ $_ ≤ $max } );
}

sub relations-for-full-path-in-region(Str $map, Str $area, Int $sf-num) {
  my ($gf-num, $gf-first-num, $gf-paths-nb, $gf-path) = access-sql::find-generic-full-path-for-specific($map, $sf-num.Int);
  my $f-num-s2g = $sf-num - $gf-first-num;

  my @words = $gf-path.comb( / \w+ / );
  my Str @t-area  = @words[0, 3 ... *];
  my Int @t-first = @words[1, 4 ... *].map({ +$_ });
  my Int @t-coef  = @words[2, 5 ... *].map({ +$_ });
  my Int @t-index = $f-num-s2g.polymod(@t-coef.reverse).reverse[1...*];

  my Int $pivot-s2g = @t-index[@t-area.first( { $_ eq $area }, :k)];

  my Int ($range1, $coef1, $coef2, $gr-num) = access-sql::find-relations($map, $gf-num, $area);
  my Int $pivot-y = $f-num-s2g % $coef2;
  my Int $pivot-x = ($f-num-s2g / $coef1).Int;
  my Int $center  = $coef2 × $pivot-x + $pivot-y;

  my @list1 = gather {
    for list-numbers($range1 × $coef2, $center) -> Int $n {
      my Int $y     = $n % $coef2;
      my Int $x     = (($n - $y) / $coef2).Int;
      my Int $n-s2g = $x × $coef1 + $pivot-s2g × $coef2 + $y;
      my Int $full  = $n-s2g + $gf-first-num;
      take ($n, $full);
    }
  }

  my @list2 = gather {
    for list-numbers(access-sql::max-path-number($map, 3, ''), $gf-num) -> $n {
      my $related = access-sql::find-related-path($map, $n, $gr-num);
      if $related {
        take ($n, $related<first_num> + $related<coef2> × $pivot-s2g);
        #say $related;
      }
    }
  }
  return (@list1, @list2);
}

sub query-from-params(%params --> Str) {
  my Str $result = '';
  for %params.kv -> $k, $v {
    $result ~= "&$k=$v";
  }
  if $result.chars == 0 {
    return '';
  }
  return '?' ~ $result.substr(1);
}

=begin POD

=encoding utf8

=head1 NAME

website1.raku -- web server which gives a user-friendly view of the Hamilton database

=head1 DESCRIPTION

This program is a web server  which manages a website showing maps and
paths stored in the Hamilton database.

=head1 USAGE

On a command-line:

  raku website1.raku

On a web browser:

  http://localhost:10000

To stop  the webserver, hit  C<Ctrl-C> on  the command line  where the
webserver was lauched.

=head1 COPYRIGHT and LICENSE

Copyright 2025 Jean Forget, all rights reserved

This  program is  published under  the  same conditions  as Raku:  the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
