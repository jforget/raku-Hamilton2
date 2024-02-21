# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant un chemin complet réduit à une région de la base de données Hamilton.db
#     Generating the HTML pages rendering a full path narrowed to a single big area from the Hamilton.db database
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package region-with-full-path;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang, :$mapcode, :%map, :%region
      ,     :@areas
      ,     :@borders
      ,     :@messages
      ,     :%path
      ,     :@rpath-links
      ,     :@fpath-links1
      ,     :@fpath-links2
      , Str :$query-string) {
  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);

  $at.at('a.full-map'   ).attr(href => "/$lang/full-map/$mapcode$query-string");
  $at.at('a.macro-map'  ).attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('a.region-map' ).attr(href => "/$lang/region-map/$mapcode/%region<code>$query-string");
  $at.at('a.full-path'  ).attr(href => "/$lang/full-path/$mapcode/%path<num>$query-string");
  $at.at('a.macro-path' ).attr(href => "/$lang/macro-path/$mapcode/%path<macro_num>$query-string");
  $at.at('a.macro-stat' ).attr(href => "/$lang/macro-stat/$mapcode$query-string");
  $at.at('a.region-path').attr(href => "/$lang/region-path/$mapcode/%region<code>/%path<num>$query-string");
  $at.at('a.region-stat').attr(href => "/$lang/region-stat/$mapcode/%region<code>$query-string");
  if %map<nb_full> != 0 {
    $at.at('a.macro-stat1').attr(href => "/$lang/macro-stat1/$mapcode$query-string");
  }
  else {
    $at.at('a.macro-stat1')».remove;
  }

  $at.at('span.region-name')».content(%region<name>);
  $at.at('span.path-number').content(%path<num>.Str);
  $at.at('span.extended-path').content(%path<path>.Str);
  if %path<cyclic> == 1 {
    $at.at('span.open')».remove;
  }
  else {
    $at.at('span.cyclic')».remove;
  }

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, path => %path<path>, query-string => $query-string, with_scale => %map<with_scale>);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at('map')».content($imagemap);

  my $links = join ' ', @rpath-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
  $at.at('p.list-of-region-paths').content($links);

  my $bug-with-full-path-links-is-fixed = 0; # to avoid buggy code
  if $bug-with-full-path-links-is-fixed {
    if @fpath-links1.elems > 0 {
      $links = join ' ', @fpath-links1.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
      $at.at('span.full-paths-1').content($links);
    }
    if @fpath-links2.elems > 0 {
      $links = join ' ', @fpath-links2.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
      $at.at('span.full-paths-2').content($links);
    }
  }

  $at.at('ul.messages').content(messages-list::render($lang, @messages));
}

our sub render(Str :$lang, Str :$mapcode, :%map, :%region, :@areas, :@borders, :@messages, :%path, :@rpath-links, :@fpath-links1, :@fpath-links2, :$query-string) {
  my &filling = anti-template :source("html/region-with-full-path.$lang.html".IO.slurp), &fill;
  return filling( lang           => $lang
                , mapcode        => $mapcode
                , map            => %map
                , region         => %region
                , areas          => @areas
                , borders        => @borders
                , messages       => @messages
                , path           => %path
                , rpath-links    => @rpath-links
                , fpath-links1   => @fpath-links1
                , fpath-links2   => @fpath-links2
                , query-string   => $query-string
                );
}


=begin POD

=encoding utf8

=head1 NAME

region-with-full-path.rakumod -- utility module to render a full path narrowed to a big area.

=head1 DESCRIPTION

This module  builds the HTML file  rendering a full path  available in
the   Hamilton   SQLite   database.   It   is   used   internally   by
C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, 2023, 2024 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
