# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant un chemin régional de la base de données Hamilton.db
#     Generating the HTML pages rendering a regional path from the Hamilton.db database
#     Copyright (C) 2022, 2023, 2024, 2025 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package deriv-ico-path;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang
        ,     :$mapcode
        ,     :%map
        ,     :%region
        ,     :@areas
        ,     :@borders
        ,     :@messages
        ,     :%deriv
        ,     :%actual-path
        ,     :%canon-path
        ,     :@cpath-links
        ,     :@ipath-links
        ,     :%isometries
        ,     :%query-params
        , Str :$query-string) {
  my $step = $at.at('ol li.step1');
  my Str $before      = %isometries<Id><transform>;
  my Str $region-code = %region<code>;

  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);
  $at.at('a.full-map'      ).attr(href => "/$lang/full-map/$mapcode$query-string");
  $at.at('a.macro-map'     ).attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('a.region-map'    ).attr(href => "/$lang/region-map/$mapcode/%region<code>$query-string");
  $at.at('a.region-path'   ).attr(href => "/$lang/region-path/$mapcode/$region-code/%actual-path<num>$query-string");
  $at.at('a.canonical-path').attr(href => "/$lang/region-path/$mapcode/$region-code/%canon-path<num>$query-string");

  $at.at('h2.path  span.region-name')».content(%region<name>);
  $at.at('h2.path  span.path-number').content(%actual-path<num>.Str);
  $at.at('h2.deriv span.region-name')».content(%region<name>);
  $at.at('h2.deriv span.path-number').content(%actual-path<num>.Str);
  $at.at('span.extended-canon-path' ).content(%canon-path<path>.Str);
  $at.at('span.extended-actual-path').content(%actual-path<path>.Str);
  if %actual-path<cyclic> == 1 {
    $at.at('span.open')».remove;
  }
  else {
    $at.at('span.cyclic')».remove;
  }

  my ($png, Str $imagemap) = map-gd::draw(@areas
                                        , @borders
                                        , path         => %actual-path<path>
                                        , query-string => $query-string
                                        , query-params => %query-params
                                        , with_scale   => %map<with_scale>);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at('map')».content($imagemap);

  my Str $step-list = '';
  my Str $step-path    = %canon-path<path>;
  my     @step-areas   = @areas;
  my     @step-borders = @borders;
  my @list-isom = <Id>;
  if %deriv<isometry> eq 'Id' {
    $at.at('p.yesderiv1')».remove;
    $at.at('ol.deriv1').content('');
    $at.at('ol.deriv1')».remove;
  }
  else {
    $at.at('p.noderiv')».remove;
    for 1..%deriv<isometry>.chars -> $i {
      push @list-isom, %deriv<isometry>.substr(0, $i);
    }
    for @list-isom -> Str $isom {
      for @areas -> $area {
        $area<code> .= trans($before => %isometries{$isom}<transform>);
      }
      for @borders -> $border {
        $border<code_f> .= trans($before => %isometries{$isom}<transform>);
        $border<code_t> .= trans($before => %isometries{$isom}<transform>);
      }
      $step-path    = %canon-path<path>;
      $step-path .= trans($before => %isometries{$isom}<transform>);
      my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, path => $step-path, query-string => $query-string, with_scale => %map<with_scale>);
      $step.at('span.isom').content($isom);
      $step.at('span.path').content($step-path);
      $step.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
      $step-list ~= "$step\n";

      my Str $transform-back = %isometries{$isom}<recipr>;
      for @areas -> $area {
        $area<code> .= trans($before => $transform-back);
      }
      for @borders -> $border {
        $border<code_f> .= trans($before => $transform-back);
        $border<code_t> .= trans($before => $transform-back);
      }
    }
    $at.at('ol.deriv1').content($step-list);

  }

  my $links = join ' ', @ipath-links.map( { "<a href='$_$query-string'>{$_}</a>" } );
  $at.at('span.same-isom').content($links);

  $links = join ' ', @cpath-links.map( { "<a href='$_$query-string'>{$_}</a>" } );
  $at.at('span.same-canon').content($links);

  $at.at('ul.messages').content(messages-list::render($lang, @messages));
}

our sub render(Str :$lang
             , Str :$mapcode
             ,     :%map
             ,     :%region
             ,     :@areas
             ,     :@borders
             ,     :%deriv
             ,     :%canon-path
             ,     :%actual-path
             ,     :@messages
             ,     :@ipath-links
             ,     :@cpath-links
             ,     :%isometries
             ,     :%query-params
             , Str :$query-string) {
  my &filling = anti-template :source("html/deriv-ico-path.$lang.html".IO.slurp), &fill;
  return filling( lang           => $lang
                , mapcode        => $mapcode
                , map            => %map
                , region         => %region
                , areas          => @areas
                , borders        => @borders
                , messages       => @messages
                , deriv          => %deriv
                , canon-path     => %canon-path
                , actual-path    => %actual-path
                , ipath-links    => @ipath-links
                , cpath-links    => @cpath-links
                , isometries     => %isometries
                , query-params   => %query-params
                , query-string   => $query-string
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

Copyright 2022, 2023, 2024, 2025 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
