# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant un chemin complet de la base de données Hamilton.db
#     Generating the HTML pages rendering a full path from the Hamilton.db database
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package full-path;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang, :$mapcode, :%map, :@areas, :@borders, :@messages, :%path
      ,     :@links
      ,     :@ico-links
      ,     :%query-params
      , Str :$query-string) {
  my Int $path-number  = %path<num>;
  my Int $macro-number = %path<macro_num>;
  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);

  $at.at('span.extended-path').content(%path<path>.Str);
  if %path<cyclic> == 1 {
    $at.at('span.open')».remove;
  }
  else {
    $at.at('span.cyclic')».remove;
  }

  my ($png, Str $imagemap) = map-gd::draw(@areas
                                        , @borders
                                        , path         => %path<path>
                                        , query-string => $query-string
                                        , query-params => %query-params
                                        , with_scale   => %map<with_scale>);
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
  $at.at('a.macro-path').attr(href => "/$lang/macro-path/$mapcode/$macro-number$query-string");
  $at('map')».content($imagemap);
  $at.at('span.path-number').content($path-number.Str);
  $at.at('ul.messages').content(messages-list::render($lang, @messages));
  my $links = join ' ', @links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
  $at.at('p.list-of-paths').content($links);
  if @ico-links.elems == 0 {
    $at.at('div.ico')».content('');
  }
  else {
    my Str $region = $mapcode.uc;
    $links = join ' ', @ico-links.map( { "<a href='/$lang/region-path/$mapcode/$region/$_$query-string'>{$_}</a>" } );
    $at.at('p.list-of-ico-paths').content($links);
  }
}

our sub render(Str $lang, Str $map, %map, :@areas, :@borders, :@messages, :%path
             ,     :@links
             ,     :@ico-links
             ,     :%query-params
             , Str :$query-string) {
  my &filling = anti-template :source("html/full-path.$lang.html".IO.slurp), &fill;
  return filling( lang         => $lang
                , mapcode      => $map
                , map          => %map
                , areas        => @areas
                , borders      => @borders
                , messages     => @messages
                , path         => %path
                , links        => @links
                , ico-links    => @ico-links
                , query-params => %query-params
                , query-string => $query-string
                );
}


=begin POD

=encoding utf8

=head1 NAME

full-path.rakumod -- utility module to render a full path.

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
