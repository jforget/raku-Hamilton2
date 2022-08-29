# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML énumérant les cartes de la base de données Hamilton.db
#     Generating the HTML pages listing the maps from the Hamilton.db database
#     Copyright (C) 2022 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package map-list-page;

use Template::Anti :one-off;

sub fill($at, :$lang, :@list) {
  my Str $list = '';
  my $line = $at.at('ul li.map');

  $at('ul li')».remove;
  for @list -> $elem {
    my ($code, $name) = @$elem;
    #say $code;
    #say $name;
    $line.at('a'        ).attr(href => "/$lang/full-map/$code");
    $line.at('a'        ).content($code);
    $line.at('span.name').content($name);
    $list ~= "$line\n";
  }
  $at.at('ul').append-content($list);
  #return $at;
}

our sub render(Str $lang, @maps) {
  my &filling = anti-template :source("html/map-list.$lang.html".IO.slurp), &fill;
  return filling(lang => $lang, list => @maps);
}


=begin POD

=encoding utf8

=head1 NAME

map-list-page.rakumod -- utility module to render the list of maps

=head1 DESCRIPTION

This module  builds the HTML  file listing  the maps available  in the
Hamilton SQLite database. It is used internally by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
