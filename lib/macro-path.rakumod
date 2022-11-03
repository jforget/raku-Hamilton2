# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant un macro-chemin de la base de données Hamilton.db
#     Generating the HTML pages rendering a macro-path from the Hamilton.db database
#     Copyright (C) 2022 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package macro-path;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang, :$mapcode, :%map, :@areas, :@borders, :@messages, :%path, :@macro-links, :@full-links) {
  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);

  $at.at('span.extended-path').content(%path<path>.Str);
  if %path<cyclic> == 1 {
    $at.at('span.open')».remove;
  }
  else {
    $at.at('span.cyclic')».remove;
  }

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, path => %path<path>);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at.at('a.full-map' ).attr(href => "/$lang/full-map/$mapcode");
  $at.at('a.macro-map').attr(href => "/$lang/macro-map/$mapcode");
  $at('map')».content($imagemap);
  $at.at('span.path-number').content(%path<num>.Str);
  $at.at('ul.messages').content(messages-list::render($lang, @messages));
  my $links = join ' ', @macro-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
  $at.at('p.list-of-paths').content($links);

  if @full-links.elems eq 0 {
    $at.at('p.list-of-full-paths')».remove;
  }
  else {
    my $links = join ' ', @full-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
    $at.at('p.list-of-full-paths').content($links);
    $at.at('p.empty-list-of-full-paths')».remove;
  }
}

our sub render(Str $lang, Str $map, %map, :@areas, :@borders, :@messages, :%path, :@macro-links, :@full-links) {
  my &filling = anti-template :source("html/macro-path.$lang.html".IO.slurp), &fill;
  return filling( lang     => $lang
                , mapcode  => $map
                , map      => %map
                , areas    => @areas
                , borders  => @borders
                , messages => @messages
                , path     => %path
                , macro-links => @macro-links
                , full-links  => @full-links
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

Copyright 2022, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
