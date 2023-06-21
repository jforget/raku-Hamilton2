# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant un chemin régional de la base de données Hamilton.db
#     Generating the HTML pages rendering a regional path from the Hamilton.db database
#     Copyright (C) 2022, 2023 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package region-path;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang, :$mapcode, :%map, :%region, :@areas, :@borders, :@messages, :%path, :@rpath-links, :@fpath-links) {
  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);

  $at.at('a.full-map' ).attr(href => "/$lang/full-map/$mapcode");
  $at.at('a.macro-map').attr(href => "/$lang/macro-map/$mapcode");
  $at.at('a.region-map').attr(href => "/$lang/region-map/$mapcode/%region<code>");

  $at.at('span.region-name')».content(%region<name>);
  $at.at('span.path-number').content(%path<num>.Str);
  $at.at('span.extended-path').content(%path<path>.Str);
  if %path<cyclic> == 1 {
    $at.at('span.open')».remove;
  }
  else {
    $at.at('span.cyclic')».remove;
  }

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, path => %path<path>);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at('map')».content($imagemap);

  my $links = join ' ', @rpath-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
  $at.at('p.list-of-region-paths').content($links);

  if @fpath-links.elems eq 0 {
    $at.at('p.list-of-full-paths')».remove;
  }
  else {
    $links = join ' ', @fpath-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
    $at.at('p.list-of-full-paths').content($links);
    $at.at('p.empty-list-of-full-paths')».remove;
  }

  $at.at('ul.messages').content(messages-list::render($lang, @messages));
}

our sub render(Str :$lang, Str :$mapcode, :%map, :%region, :@areas, :@borders, :@messages, :%path, :@rpath-links, :@fpath-links) {
  my &filling = anti-template :source("html/region-path.$lang.html".IO.slurp), &fill;
  return filling( lang     => $lang
                , mapcode  => $mapcode
                , map      => %map
                , region   => %region
                , areas    => @areas
                , borders  => @borders
                , messages => @messages
                , path     => %path
                , rpath-links    => @rpath-links
                , fpath-links    => @fpath-links
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

Copyright 2022, 2023, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
