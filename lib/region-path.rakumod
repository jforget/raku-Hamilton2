# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant un chemin régional de la base de données Hamilton.db
#     Generating the HTML pages rendering a regional path from the Hamilton.db database
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package region-path;

use Template::Anti :one-off;
use common;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang, :$mapcode, :%map, :%region, :@areas, :@borders, :@messages
        ,     :%path
        ,     :@rpath-links
        ,     :@fpath-links
        ,     :@ico-links
        ,     :%reverse-link
        , Str :$query-string) {

  common::links($at, lang         => $lang
                   , mapcode      => $mapcode
                   , map          => %map
                   , region       => %region
                   , messages     => @messages
                   , macro-links  => ()
                   , full-links   => @fpath-links
                   , region-links => @rpath-links
                   , canon-links  => @fpath-links
                   , reverse-link => %reverse-link
                   , query-string => $query-string);
  $at('title')».content(%map<name>);

  if %map<nb_full> != 0 {
    $at.at('a.macro-stat1').attr(href => "/$lang/macro-stat1/$mapcode$query-string");
  }
  else {
    $at.at('a.macro-stat1')».remove;
  }
  if %map<with_isom> == 1 {
    $at.at('a.path-derivation').attr(href => "/$lang/deriv-ico-path/$mapcode/%path<num>$query-string");
  }
  else {
    $at.at('a.path-derivation')».remove;
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

  if @ico-links.elems == 0 {
    $at.at('div.ico')».content('');
  }
  else {
    my Str $region = %region<code>;
    my $links = join ' ', @ico-links.map( { "<a href='/$lang/region-path/$mapcode/$region/$_$query-string'>{$_}</a>" } );
    $at.at('p.list-of-ico-paths').content($links);
  }

}

our sub render(Str :$lang
             , Str :$mapcode
             ,     :%map
             ,     :%region
             ,     :@areas
             ,     :@borders
             ,     :@messages
             ,     :%path
             ,     :@rpath-links
             ,     :@fpath-links
             ,     :@ico-links
             ,     :%reverse-link
             , Str :$query-string) {
  my &filling = anti-template :source("html/region-path.$lang.html".IO.slurp), &fill;
  return filling( lang     => $lang
                , mapcode  => $mapcode
                , map      => %map
                , region   => %region
                , areas    => @areas
                , borders  => @borders
                , messages     => @messages
                , path         => %path
                , rpath-links  => @rpath-links
                , fpath-links  => @fpath-links
                , ico-links    => @ico-links
                , reverse-link => %reverse-link
                , query-string => $query-string
                );
}


=begin POD

=encoding utf8

=head1 NAME

region-path.rakumod -- utility module to render a region path.

=head1 DESCRIPTION

This module builds the HTML file  rendering a region path available in
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
