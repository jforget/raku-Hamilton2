# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant une carte de la base de données Hamilton.db
#     Generating the HTML pages rendering a map from the Hamilton.db database
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package map;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;
use common;

sub fill($at, :$lang
        ,     :$mapcode
        ,     :%map
        ,     :%region
        ,     :@areas
        ,     :@borders
        ,     :@messages
        ,     :@macro-links
        ,     :@full-links
        ,     :@region-links
        ,     :@canon-links
        , Str :$query-string) {

  common::links($at, lang         => $lang
                   , mapcode      => $mapcode
                   , map          => %map
                   , region       => %region
                   , messages     => @messages
                   , macro-links  => @macro-links
                   , full-links   => @full-links
                   , region-links => @region-links
                   , canon-links  => @canon-links
                   , query-string => $query-string);

  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, query-string => $query-string, with_scale => %map<with_scale>);

  if %region<code>:!exists {
    $at.at('div.region').content('');
    $at.at('a.region-map-link')».remove;
    $at.at('a.region-stat-link')».remove;
    $at.at('a.shpth-region-link')».remove;
    $at.at('span.fruitless-reason-region')».remove;
    $at.at('p.fruitless-region')».remove;
  }
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at.at('a.macro-map' ).attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('a.macro-stat').attr(href => "/$lang/macro-stat/$mapcode$query-string");
  if %map<nb_full> != 0 {
    $at.at('a.macro-stat1').attr(href => "/$lang/macro-stat1/$mapcode$query-string");
  }
  else {
    $at.at('a.macro-stat1')».remove;
  }
  $at('map')».content($imagemap);

  if %map<fruitless_reason> eq '' {
    $at.at('span.fruitless-reason-macro')».remove;
    $at.at('p.fruitless-macro')».remove;
  }
  else {
    $at.at('span.fruitless-reason-macro').content(%map<fruitless_reason>);
  }

  if %region<fruitless_reason> // '' eq '' {
    $at.at('span.fruitless-reason-region')».remove;
    $at.at('p.fruitless-region')».remove;
  }
  else {
    $at.at('span.fruitless-reason-region').content(%region<fruitless_reason>);
  }

}

our sub render(Str $lang
             , Str $map
             ,     :%map
             ,     :%region
             ,     :@areas
             ,     :@borders
             ,     :@messages
             ,     :@macro-links
             ,     :@full-links
             ,     :@region-links
             ,     :@canon-links
             , Str :$query-string) {
  my &filling = anti-template :source("html/map.$lang.html".IO.slurp), &fill;
  return filling(lang         => $lang
               , mapcode      => $map
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
               );
}


=begin POD

=encoding utf8

=head1 NAME

map.rakumod -- utility module to render a map.

=head1 DESCRIPTION

This module  builds the  HTML file  rendering a  map available  in the
Hamilton SQLite database. It is used internally by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, 2023, 2024 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the license is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
