# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant une carte de la base de données Hamilton.db
#     Generating the HTML pages rendering a map from the Hamilton.db database
#     Copyright (C) 2022 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package macro-map;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;

sub fill($at, :$lang, :$mapcode, :%map, :@areas, :@borders) {
  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at.at('a.full-map').attr(href => "/$lang/full-map/$mapcode");
  $at('map')».content($imagemap);
}

our sub render(Str $lang, Str $map, %map, @areas, @borders) {
  my &filling = anti-template :source("html/macro-map.$lang.html".IO.slurp), &fill;
  return filling(lang => $lang, mapcode => $map, map => %map, areas => @areas, borders => @borders);
}


=begin POD

=encoding utf8

=head1 NAME

map-page.rakumod -- utility module to render a map.

=head1 DESCRIPTION

This module  builds the  HTML file  rendering a  map available  in the
Hamilton SQLite database. It is used internally by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
