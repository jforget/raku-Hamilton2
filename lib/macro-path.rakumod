# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant un macro-chemin de la base de données Hamilton.db
#     Generating the HTML pages rendering a macro-path from the Hamilton.db database
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package macro-path;

use Template::Anti :one-off;
use common;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang, :$mapcode, :%map, :@areas, :@borders, :@messages, :%path
        ,     :@macro-links
        ,     :@full-links
        ,     :@ico-links
        ,     :%reverse-link
        , Str :$query-string) {

  common::links($at, lang         => $lang
                   , mapcode      => $mapcode
                   , map          => %map
                   , region       => %()
                   , messages     => @messages
                   , macro-links  => @macro-links
                   , full-links   => @full-links
                   , region-links => ()
                   , canon-links  => ()
                   , reverse-link => %reverse-link
                   , query-string => $query-string);

  $at('title')».content(%map<name>);

  $at.at('span.extended-path').content(%path<path>.Str);
  if %path<cyclic> == 1 {
    $at.at('span.open')».remove;
  }
  else {
    $at.at('span.cyclic')».remove;
  }

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, path => %path<path>, query-string => $query-string, with_scale => %map<with_scale>);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at.at('a.full-map'  ).attr(href => "/$lang/full-map/$mapcode$query-string");
  $at.at('a.macro-map' ).attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('a.macro-stat').attr(href => "/$lang/macro-stat/$mapcode$query-string");
  if %map<nb_full> != 0 {
    $at.at('a.macro-stat1').attr(href => "/$lang/macro-stat1/$mapcode$query-string");
  }
  else {
    $at.at('a.macro-stat1')».remove;
  }
  $at('map')».content($imagemap);
  $at.at('span.path-number').content(%path<num>.Str);

  if %path<fruitless> == 1 {
    $at('span.fruitless-reason')».content(%path<fruitless_reason>);
    $at('p.list-of-full-paths'      )».remove;
    $at('p.empty-list-of-full-paths')».remove;
  }
  elsif @full-links.elems == 0 {
    $at('p.fruitless-path'    )».remove;
  }
  else {
    $at('p.fruitless-path'          )».remove;
  }

  if @ico-links.elems == 0 {
    $at.at('div.ico')».content('');
  }
  else {
    my Str $region = $mapcode.uc;
    my $links = join ' ', @ico-links.map( { "<a href='/$lang/region-path/$mapcode/$region/$_$query-string'>{$_}</a>" } );
    $at.at('p.list-of-ico-paths').content($links);
  }
}

our sub render(Str $lang, Str $map, %map, :@areas, :@borders, :@messages, :%path
            ,     :@macro-links
            ,     :@full-links
            ,     :@ico-links
            ,     :%reverse-link
            , Str :$query-string) {
  my &filling = anti-template :source("html/macro-path.$lang.html".IO.slurp), &fill;
  return filling( lang           => $lang
                , mapcode        => $map
                , map            => %map
                , areas          => @areas
                , borders        => @borders
                , messages       => @messages
                , path           => %path
                , macro-links    => @macro-links
                , full-links     => @full-links
                , ico-links      => @ico-links
                , reverse-link   => %reverse-link
                , query-string   => $query-string
                );
}


=begin POD

=encoding utf8

=head1 NAME

macro-path.rakumod -- utility module to render a macro-path.

=head1 DESCRIPTION

This module builds  the HTML file rendering a  macro-path available in
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
