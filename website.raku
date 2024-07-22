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
use Bailador;

use access-sql;
use map-list-page;
use map;
use common;
use full-path;
use macro-path;
use Hamilton-stat;
use region-path;
use region-with-full-path;
use deriv-ico-path;
use shortest-path-stat;
use Graph:from<Perl5>;

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
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
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

  return map::render($lng, $map
                   , map          => %map
                   , region       => %()
                   , areas        => @areas
                   , borders      => @borders
                   , messages     => @messages
                   , macro-links  => @macro-links
                   , full-links   => @full-links
                   , region-links => ()
                   , canon-links  => @canon-links
                   , query-string => $query-string
                   );
}

get '/:ln/macro-map/:map' => sub ($lng_parm, $map_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
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

  return map::render($lng, $map
                   , map          => %map
                   , region       => %()
                   , areas        => @areas
                   , borders      => @borders
                   , messages     => @messages
                   , macro-links  => @macro-links
                   , full-links   => @full-links
                   , region-links => ()
                   , canon-links  => @canon-links
                   , query-string => $query-string
                   );
}

get '/:ln/region-map/:map/:region' => sub ($lng_parm, $map_parm, $reg_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $query-string = query-string;

  my Str $region = ~ $reg_parm;
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
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
  return map::render($lng, $map
                   , map          => %map
                   , region       => %region
                   , areas        => @areas
                   , borders      => @borders
                   , messages     => @messages
                   , macro-links  => @macro-links
                   , full-links   => @full-links
                   , region-links => @path-links
                   , canon-links  => @canon-links
                   , query-string => $query-string
                   );
}

get '/:ln/macro-path/:map/:num' => sub ($lng_parm, $map_parm, $num_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Int $num    = + $num_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
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

  return macro-path::render($lng, $map, %map
                           , areas          => @areas
                           , borders        => @borders
                           , path           => %path
                           , messages       => @messages
                           , macro-links    => @macro-links
                           , full-links     => @full-links
                           , ico-links      => @ico-links
                           , reverse-link   => %reverse-link
                           , query-string   => $query-string
                           );
}

get '/:ln/region-path/:map/:region/:num' => sub ($lng_parm, $map_parm, $region_parm, $num_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $region = ~ $region_parm;
  my Int $num    = + $num_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
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

  return region-path::render(lang     => $lng
                           , mapcode  => $map
                           , map      => %map
                           , region   => %region
                           , areas    => @areas
                           , borders  => @borders
                           , path     => %path
                           , messages => @messages
                           , rpath-links    => @links
                           , fpath-links    => @full-links[@indices]
                           , ico-links      => @ico-links
                           , query-string   => $query-string
                           );
}

get '/:ln/full-path/:map/:num' => sub ($lng_parm, $map_parm, $num_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Int $num    = + $num_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-small-areas($map);
  my @borders = access-sql::list-small-borders($map);
  for @areas -> $area {
    $area<url> = "/$lng/region-with-full-path/$map/$area<upper>/$num$query-string";
  }
  my %path       = access-sql::read-specific-path($map, $num);
  my @messages   = access-sql::list-messages($map);
  my @list-paths = list-numbers(%map<nb_full>, $num);
  my @links      = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  my @ico-links  = access-sql::list-ico-paths-for-isom($map, 'Id');

  return full-path::render($lng, $map, %map
                          , areas    => @areas
                          , borders  => @borders
                          , path     => %path
                          , messages => @messages
                          , links    => @links
                          , ico-links    => @ico-links
                          , query-string => $query-string
                          );
}

get '/:ln/region-with-full-path/:map/:region/:num' => sub ($lng_parm, $map_parm, $region_parm, $num_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $region = ~ $region_parm;
  my Int $num    = + $num_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
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
      $area<url> = "/$lng/region-with-full-path/$map/$area<upper>/$num$query-string";
    }
  }
  my %specific-path = access-sql::read-specific-path($map, $num);
  my @messages      = access-sql::list-regional-messages($map, $region);

  my @list-paths = list-numbers(%region<nb_region_paths>, $num);
  my @links      = @list-paths.map( { %( txt => $_, link => "/$lng/region-path/$map/$region/$_$query-string" ) } );

  my Int $region-num = access-sql::regional-path-of-full($map, $region, $num);
  my @full-numbers   = access-sql::path-relations($map, $region, $region-num);

  my @rel = relations-for-full-path-in-region($map, $region, $num);
  my $rel1 = @rel[0];
  my $rel2 = @rel[1];
  my @links1 = $rel1.map( { %( txt => "$_[0]:$_[1]", link => "/$lng/full-path/$map/$_[1]$query-string" ) } );
  my @links2 = $rel2.map( { %( txt => "$_[0]:$_[1]", link => "/$lng/full-path/$map/$_[1]$query-string" ) } );

  return region-with-full-path::render(lang           => $lng
                                     , mapcode        => $map
                                     , map            => %map
                                     , region         => %region
                                     , areas          => @areas
                                     , borders        => @borders
                                     , path           => %specific-path
                                     , messages       => @messages
                                     , rpath-links    => @links
                                     , fpath-links1   => @links1
                                     , fpath-links2   => @links2
                                     , query-string   => $query-string
                                     );
}

get '/:ln/deriv-ico-path/:map/:num' => sub ($lng_parm, $map_parm, $num_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $region = $map.uc;
  my Int $num    = + $num_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
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
  my %deriv-path  = access-sql::read-deriv($map, $num);
  my %actual-path = access-sql::read-path( $map, 2, $region, $num);
  my %canon-path  = access-sql::read-path( $map, 2, $region, %deriv-path<canonical_num>);
  my @messages    = access-sql::list-regional-messages($map, $region);

  my @list-paths = list-numbers(%region<nb_region_paths>, $num);
  my @links      = @list-paths.map( { %( txt => $_, link => "/$lng/region-path/$map/$region/$_$query-string" ) } );

  my @full-numbers = access-sql::path-relations($map, $region, $num);
  my @full-links;
  for @full-numbers.kv -> $i, $num {
    push @full-links, %(txt => "{$i + 1}:$num", link => "http:/$lng/full-path/$map/$num$query-string");
  }
  my @indices = list-numbers(@full-numbers.elems, $num) «-» 1;
  my @ipaths  = access-sql::list-ico-paths-same-isom( $map, $num);
  my @cpaths  = access-sql::list-ico-paths-same-canon($map, $num);
  my %isometries;
  for access-sql::list-isometries($map) -> $isometry {
    %isometries{$isometry<isometry>} = $isometry;
  }

  return deriv-ico-path::render(lang           => $lng
                              , mapcode        => $map
                              , map            => %map
                              , region         => %region
                              , areas          => @areas
                              , borders        => @borders
                              , deriv          => %deriv-path
                              , canon-path     => %canon-path
                              , actual-path    => %actual-path
                              , messages       => @messages
                              , ipath-links    => @ipaths
                              , cpath-links    => @cpaths
                              , isometries     => %isometries
                              , query-string   => $query-string
                              );
}

get '/:ln/region-stat/:map/:region' => sub ($lng_parm, $map_parm, $reg_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $query-string = query-string;

  my Str $region = ~ $reg_parm;
  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map        = access-sql::read-map($map);
  my %region     = access-sql::read-region(            $map, $region);
  my @areas      = access-sql::list-areas-in-region(   $map, $region);
  my @neighbours = access-sql::list-neighbour-areas(   $map, $region);
  my @borders    = access-sql::list-borders-for-region($map, $region);

  @areas.append(@neighbours);
  for @areas -> $area {
    if $area<upper> eq $region {
      $area<url> = "/$lng/region-map/$map/$area<upper>$query-string";
      $area<nb_paths_stat> = $area<nb_region_paths>;
    }
    else {
      $area<url> = "/$lng/region-stat/$map/$area<upper>$query-string";
    }
  }
  for @borders -> $border {
    if $border<color> ne 'Black' {
      $border<nb_paths_stat> = $border<nb_paths>;
    }
  }

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt  => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths      = list-numbers(%map<nb_full>, 0);
  my @full-links   = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  @list-paths      = list-numbers(%region<nb_region_paths>, 0);
  my @region-links = @list-paths.map( { %( txt => $_, link => "/$lng/region-path/$map/$region/$_$query-string" ) } );
  my @canon-links  = access-sql::list-ico-paths-for-isom($map, 'Id');

  my @messages = access-sql::list-regional-messages($map, $region);
  return Hamilton-stat::render($lng, $map
                             , map          => %map
                             , region       => %region
                             , areas        => @areas
                             , borders      => @borders
                             , messages     => @messages
                             , macro-links  => @macro-links
                             , full-links   => @full-links
                             , region-links => @region-links
                             , canon-links  => @canon-links
                             , query-string => $query-string
                             , variant      => False
                             );
}

get '/:ln/macro-stat/:map' => sub ($lng_parm, $map_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-big-areas($map);
  my @borders = access-sql::list-big-borders($map);
  for @areas -> $area {
    $area<url> = "/$lng/region-stat/$map/$area<code>$query-string";
    $area<nb_paths_stat> = $area<nb_macro_paths>;
  }
  for @borders -> $border {
    $border<nb_paths_stat> = $border<nb_paths>;
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

  return Hamilton-stat::render($lng, $map
                             , map          => %map
                             , region       => %()
                             , areas        => @areas
                             , borders      => @borders
                             , messages     => @messages
                             , macro-links  => @macro-links
                             , full-links   => @full-links
                             , canon-links  => @canon-links
                             , query-string => $query-string
                             , variant      => False
                             );
}

get '/:ln/macro-stat1/:map' => sub ($lng_parm, $map_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-big-areas($map);
  my @borders = access-sql::list-big-borders($map);
  for @areas -> $area {
    $area<url> = "/$lng/region-stat/$map/$area<code>$query-string";
    $area<nb_paths_stat> = $area<nb_macro_paths_1>;
  }
  for @borders -> $border {
    $border<nb_paths_stat> = $border<nb_paths_1>;
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

  return Hamilton-stat::render($lng, $map
                             , map          => %map
                             , region       => %()
                             , areas        => @areas
                             , borders      => @borders
                             , messages     => @messages
                             , macro-links  => @macro-links
                             , full-links   => @full-links
                             , canon-links  => @canon-links
                             , query-string => $query-string
                             , variant      => True
                             );
}

get '/:ln/shortest-path/macro/:map' => sub ($lng_parm, $map_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-big-areas($map);
  my @borders = access-sql::list-big-borders($map);
  for @areas -> $area {
    $area<url>     = "/$lng/shortest-path/region/$map/$area<code>$query-string";
    $area<tbl-url> = "/$lng/shortest-paths-from/macro/$map/$area<code>$query-string";
    $area<stat>    = $area<full_eccentricity>;
  }
  %map<diameter> = %map<macro_diameter>;
  %map<radius  > = %map<macro_radius  >;
  my @messages = access-sql::list-messages($map);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths     = list-numbers(%map<nb_full>, 0);
  my @full-links  = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  my @canon-links = access-sql::list-ico-paths-for-isom($map, 'Id');

  return shortest-path-stat::render($lng, $map, %map, %()
                           , areas        => @areas
                           , borders      => @borders
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , canon-links  => @canon-links
                           , region-links => ()
                           , query-string => $query-string
                           );
}

get '/:ln/shortest-path/full/:map' => sub ($lng_parm, $map_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-small-areas(  $map);
  my @borders = access-sql::list-small-borders($map);
  for @areas -> $area {
    $area<url>     = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
    $area<tbl-url> = "/$lng/shortest-paths-from/full/$map/$area<code>$query-string";
    $area<stat>    = $area<full_eccentricity>;
  }
  %map<diameter> = %map<full_diameter>;
  %map<radius  > = %map<full_radius  >;
  my @messages = access-sql::list-messages($map);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths     = list-numbers(%map<nb_full>, 0);
  my @full-links  = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  my @canon-links = access-sql::list-ico-paths-for-isom($map, 'Id');

  return shortest-path-stat::render($lng, $map, %map, %()
                           , areas        => @areas
                           , borders      => @borders
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , canon-links  => @canon-links
                           , region-links => ()
                           , query-string => $query-string
                           );
}

get '/:ln/shortest-path/region/:map/:region' => sub ($lng_parm, $map_parm, $region_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $region = ~ $region_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map        = access-sql::read-map($map);
  my %region     = access-sql::read-region(            $map, $region);
  my @areas      = access-sql::list-areas-in-region(   $map, $region);
  my @neighbours = access-sql::list-neighbour-areas(   $map, $region);
  my @borders    = access-sql::list-borders-for-region($map, $region);

  @areas.append(@neighbours);
  for @areas -> $area {
    if $area<upper> eq $region {
      $area<url>     = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
      $area<tbl-url> = "/$lng/shortest-paths-from/region/$map/$area<upper>/$area<code>$query-string";
      $area<stat>    = $area<region_eccentricity>;
    }
    else {
      $area<url>  = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
    }
  }
  my @messages = access-sql::list-regional-messages($map, $region);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths      = list-numbers(%map<nb_full>, 0);
  my @full-links   = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  @list-paths      = list-numbers(%region<nb_region_paths>, 0);
  my @region-links = @list-paths.map( { %( txt => $_, link => "/$lng/region-path/$map/$region/$_$query-string" ) } );
  my @canon-links  = access-sql::list-ico-paths-for-isom($map, 'Id');

  return shortest-path-stat::render($lng, $map, %map, %region
                           , areas        => @areas
                           , borders      => @borders
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , region-links => @region-links
                           , canon-links  => @canon-links
                           , query-string => $query-string
                           );
}

get '/:ln/shortest-paths-from/macro/:map/:area' => sub ($lng_parm, $map_parm, $area_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $area-code = ~ $area_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-big-areas($map);
  my @borders = access-sql::list-big-borders($map);

  my @area-codes = @areas.map( { $_<code> } );
  my @border-codes = ();
  for @borders -> $border {
    if $border<code_f> lt $border<code_t> {
      @border-codes.push([$border<code_f>, $border<code_t>]);
    }
  }
  my $graph = Graph.new(undirected => 1
                      , vertices   => @area-codes
                      , edges      => @border-codes);
  my $apsp = $graph.APSP_Floyd_Warshall;

  for @areas -> $area {
    $area<url>  = "/$lng/shortest-path/region/$map/$area<code>$query-string";
    $area<stat> = $apsp.path_length($area-code, $area<code>) // @areas.elems;
    $area<tbl-url> = "/$lng/shortest-paths-from-to/macro/$map/$area-code/$area<code>$query-string";
  }
  my @messages = access-sql::list-messages($map);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths     = list-numbers(%map<nb_full>, 0);
  my @full-links  = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  my @canon-links = access-sql::list-ico-paths-for-isom($map, 'Id');

  return shortest-path-stat::render-from($lng, $map, %map, %()
                           , from         => $area-code
                           , areas        => @areas
                           , borders      => @borders
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , canon-links  => @canon-links
                           , region-links => ()
                           , query-string => $query-string
                           );
}

get '/:ln/shortest-paths-from/full/:map/:area' => sub ($lng_parm, $map_parm, $area_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $area-code = ~ $area_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-small-areas(  $map);
  my @borders = access-sql::list-small-borders($map);

  my @area-codes = @areas.map( { $_<code> } );
  my @border-codes = ();
  for @borders -> $border {
    if $border<code_f> lt $border<code_t> {
      @border-codes.push([$border<code_f>, $border<code_t>]);
    }
  }
  my $graph = Graph.new(undirected => 1
                      , vertices   => @area-codes
                      , edges      => @border-codes);
  my $apsp = $graph.APSP_Floyd_Warshall;

  for @areas -> $area {
    $area<url>  = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
    $area<stat> = $apsp.path_length($area-code, $area<code>) // @areas.elems;
    $area<tbl-url> = "/$lng/shortest-paths-from-to/full/$map/$area-code/$area<code>$query-string";
  }
  my @messages = access-sql::list-messages($map);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths     = list-numbers(%map<nb_full>, 0);
  my @full-links  = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  my @canon-links = access-sql::list-ico-paths-for-isom($map, 'Id');

  return shortest-path-stat::render-from($lng, $map, %map, %()
                           , from         => $area-code
                           , areas        => @areas
                           , borders      => @borders
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , canon-links  => @canon-links
                           , region-links => ()
                           , query-string => $query-string
                           );
}

get '/:ln/shortest-paths-from/region/:map/:region/:area' => sub ($lng_parm, $map_parm, $region_parm, $area_parm) {
  my Str $lng    = ~ $lng_parm;
  my Str $map    = ~ $map_parm;
  my Str $region = ~ $region_parm;
  my Str $area-code = ~ $area_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map        = access-sql::read-map($map);
  my %region     = access-sql::read-region(            $map, $region);
  my @areas      = access-sql::list-areas-in-region(   $map, $region);
  my @neighbours = access-sql::list-neighbour-areas(   $map, $region);
  my @borders    = access-sql::list-borders-for-region($map, $region);

  my @area-codes = @areas.map( { $_<code> } );
  my @border-codes = gather {
    for access-sql::list-borders-in-region($map, $region) -> $border {
      if $border<code_f> lt $border<code_t> {
        take ([$border<code_f>, $border<code_t>]);
      }
    }
  }
  my $graph = Graph.new(undirected => 1
                      , vertices   => @area-codes
                      , edges      => @border-codes);
  my $apsp = $graph.APSP_Floyd_Warshall;

  @areas.append(@neighbours);
  for @areas -> $area {
    if $area<upper> eq $region {
      $area<url>  = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
      $area<stat> = $apsp.path_length($area-code, $area<code>) // @areas.elems;
      $area<tbl-url> = "/$lng/shortest-paths-from-to/region/$map/$area<upper>/$area-code/$area<code>$query-string";
    }
    else {
      $area<url>  = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
    }
  }
  my @messages = access-sql::list-regional-messages($map, $region);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths      = list-numbers(%map<nb_full>, 0);
  my @full-links   = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  @list-paths      = list-numbers(%region<nb_region_paths>, 0);
  my @region-links = @list-paths.map( { %( txt => $_, link => "/$lng/region-path/$map/$region/$_$query-string" ) } );
  my @canon-links  = access-sql::list-ico-paths-for-isom($map, 'Id');

  return shortest-path-stat::render-from($lng, $map, %map, %region
                           , from         => $area-code
                           , areas        => @areas
                           , borders      => @borders
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , region-links => @region-links
                           , canon-links  => @canon-links
                           , query-string => $query-string
                           );
}

get '/:ln/shortest-paths-from-to/macro/:map/:from/:to' => sub ($lng_parm, $map_parm, $from_parm, $to_parm) {
  my Str $lng          = ~ $lng_parm;
  my Str $map          = ~ $map_parm;
  my Str $from-code    = ~ $from_parm;
  my Str $to-code      = ~ $to_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-big-areas($map);
  my @borders = access-sql::list-big-borders($map);

  for @areas -> $area {
    $area<url    > = "/$lng/shortest-path/region/$map/$area<code>$query-string";
    $area<tbl-url> = "/$lng/shortest-paths-from-to/macro/$map/$from-code/$area<code>$query-string";
  }
  my @messages = access-sql::list-messages($map);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths     = list-numbers(%map<nb_full>, 0);
  my @full-links  = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  my @canon-links = access-sql::list-ico-paths-for-isom($map, 'Id');

  my %reverse-link = %( txt  => "$to-code → $from-code"
                      , link => "/$lng/shortest-paths-from-to/macro/$map/$to-code/$from-code$query-string"
                      );

  return Hamilton-stat::render-from-to($lng, $map
                           , from         => $from-code
                           , to           => $to-code
                           , map          => %map
                           , region       => %()
                           , areas        => @areas
                           , borders      => @borders
                           , neighbours   => ()
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , canon-links  => @canon-links
                           , region-links => ()
                           , reverse-link => %reverse-link
                           , query-string => $query-string
                           );
}

get '/:ln/shortest-paths-from-to/full/:map/:from/:to' => sub ($lng_parm, $map_parm, $from_parm, $to_parm) {
  my Str $lng          = ~ $lng_parm;
  my Str $map          = ~ $map_parm;
  my Str $from-code    = ~ $from_parm;
  my Str $to-code      = ~ $to_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map     = access-sql::read-map($map);
  my @areas   = access-sql::list-small-areas(  $map);
  my @borders = access-sql::list-small-borders($map);

  for @areas -> $area {
    $area<url    > = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
    $area<tbl-url> = "/$lng/shortest-paths-from-to/full/$map/$from-code/$area<code>$query-string";
  }
  my @messages = access-sql::list-messages($map);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths     = list-numbers(%map<nb_full>, 0);
  my @full-links  = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  my @canon-links = access-sql::list-ico-paths-for-isom($map, 'Id');

  my %reverse-link = %( txt  => "$to-code → $from-code"
                      , link => "/$lng/shortest-paths-from-to/full/$map/$to-code/$from-code$query-string"
                      );

  return Hamilton-stat::render-from-to($lng, $map
                           , from         => $from-code
                           , to           => $to-code
                           , map          => %map
                           , region       => %()
                           , areas        => @areas
                           , borders      => @borders
                           , neighbours   => ()
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , canon-links  => @canon-links
                           , region-links => ()
                           , reverse-link => %reverse-link
                           , query-string => $query-string
                           );
}

get '/:ln/shortest-paths-from-to/region/:map/:region/:from/:to' => sub ($lng_parm, $map_parm, $region_parm, $from_parm, $to_parm) {
  my Str $lng          = ~ $lng_parm;
  my Str $map          = ~ $map_parm;
  my Str $region       = ~ $region_parm;
  my Str $from-code    = ~ $from_parm;
  my Str $to-code      = ~ $to_parm;
  my Str $query-string = query-string;

  if $lng !~~ /^ @languages $/ {
    return slurp('html/unknown-language.html');
  }
  my %map        = access-sql::read-map($map);
  my %region     = access-sql::read-region(            $map, $region);
  my @areas      = access-sql::list-areas-in-region(   $map, $region);
  my @neighbours = access-sql::list-neighbour-areas(   $map, $region);
  my @borders    = access-sql::list-borders-for-region($map, $region);

  for @areas -> $area {
    $area<url    > = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
    $area<tbl-url> = "/$lng/shortest-paths-from-to/region/$map/$area<upper>/$from-code/$area<code>$query-string";
  }
  for @neighbours -> $area {
    $area<url>  = "/$lng/shortest-path/region/$map/$area<upper>$query-string";
  }
  my @messages = access-sql::list-regional-messages($map, $region);

  my @list-paths  = list-numbers(%map<nb_macro>, 0);
  my @macro-links = @list-paths.map( { %( txt => $_
                                        , link => "/$lng/macro-path/$map/$_$query-string"
                                        , bold => access-sql::bold-macro-path($map, $_)
                                        ) } );

  @list-paths      = list-numbers(%map<nb_full>, 0);
  my @full-links   = @list-paths.map( { %( txt => $_, link => "/$lng/full-path/$map/$_$query-string" ) } );
  @list-paths      = list-numbers(%region<nb_region_paths>, 0);
  my @region-links = @list-paths.map( { %( txt => $_, link => "/$lng/region-path/$map/$region/$_$query-string" ) } );
  my @canon-links  = access-sql::list-ico-paths-for-isom($map, 'Id');

  my %reverse-link = %( txt  => "$to-code → $from-code"
                      , link => "/$lng/shortest-paths-from-to/region/$map/$region/$to-code/$from-code$query-string"
                      );

  return Hamilton-stat::render-from-to($lng, $map
                           , from         => $from-code
                           , to           => $to-code
                           , map          => %map
                           , region       => %region
                           , areas        => @areas
                           , borders      => @borders
                           , neighbours   => @neighbours
                           , messages     => @messages
                           , macro-links  => @macro-links
                           , full-links   => @full-links
                           , region-links => @region-links
                           , canon-links  => @canon-links
                           , reverse-link => %reverse-link
                           , query-string => $query-string
                           );
}

baile();

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

sub query-string {
  my $uri = request.uri;
  if  $uri.index('?') {
    return $uri.substr($uri.index('?'));
  }
  else {
    return '';
  }
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

Copyright 2022, 2023, 2024 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
