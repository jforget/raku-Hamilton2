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
unit package deriv-ico-path;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

my Str $before       = "BCDFGHJKLMNPQRSTVWXZ";
my Str $after-lambda = "GBCDFKLMNPQZXWRSTVJH";
my Str $after-kappa  = "PCBZQRWXHGFDMLKJVTSN";
my Str $after-iota   = "CBGFDMLKJHXZQRWVTSNP";

multi sub infix:<↣> (Str $string, Str $isom where * eq 'Id') {
  return $string;
}

multi sub infix:<↣> (Str $string, Str $isom where * ~~ /^ <[ɩκλ]> * $/) {
  my Str $resul = $string;
  for $isom.comb -> $iso {
    given $iso {
      when 'λ' { $resul .= trans($before => $after-lambda); }
      when 'κ' { $resul .= trans($before => $after-kappa ); }
      when 'ɩ' { $resul .= trans($before => $after-iota  ); }
    }
  }
  return $resul;
}

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
        ,     :@rpath-links
        ,     :@fpath-links
        , Str :$query-string) {
  my $step = $at.at('ol li.step1');

  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);

  $at.at('a.full-map'   ).attr(href => "/$lang/full-map/$mapcode$query-string");
  $at.at('a.macro-map'  ).attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('a.region-map' ).attr(href => "/$lang/region-map/$mapcode/%region<code>$query-string");
  $at.at('a.region-path').attr(href => "/$lang/region-path/ico/ICO/%actual-path<num>$query-string");

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

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, path => %actual-path<path>, query-string => $query-string);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at('map')».content($imagemap);

  my Str $step-list = '';
  my Str $step-path    = %canon-path<path>;
  my     @step-areas   = @areas;
  my     @step-borders = @borders;
  my @list-isom = <Id>;
  if %deriv<isometry> eq 'Id' {
    $at.at('p.yesderiv1')».remove;
    $at.at('p.yesderiv2')».remove;
    $at.at('ol.deriv1').content('');
    $at.at('ol.deriv2').content('');
    $at.at('ol.deriv1')».remove;
    $at.at('ol.deriv2')».remove;
  }
  else {
    $at.at('p.noderiv')».remove;
    push @list-isom, |%deriv<isometry>.comb;
    for @list-isom -> Str $isom {
      for @step-areas <-> $area {
        $area<code> = $area<code> ↣ $isom;
      }
      for @step-borders <-> $border {
        $border<code_f> = $border<code_f> ↣ $isom;
        $border<code_t> = $border<code_t> ↣ $isom;
      }
      $step-path = $step-path ↣ $isom;
      my ($png, Str $imagemap) = map-gd::draw(@step-areas, @step-borders, path => $step-path, query-string => $query-string);
      $step.at('span.isom').content($isom);
      $step.at('span.path').content($step-path);
      $step.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
      $step-list ~= "$step\n";
    }
    $at.at('ol.deriv1').content($step-list);

    $step-list = '';
    @list-isom = <Id>;
    push @list-isom,  | %deriv<recipr>.comb;
    for @list-isom -> Str $isom {
      for @step-areas <-> $area {
        $area<code> = $area<code> ↣ $isom;
      }
      for @step-borders <-> $border {
        $border<code_f> = $border<code_f> ↣ $isom;
        $border<code_t> = $border<code_t> ↣ $isom;
      }
      my ($png, Str $imagemap) = map-gd::draw(@step-areas, @step-borders, path => $step-path, query-string => $query-string);
      $step.at('span.isom').content($isom);
      $step.at('span.path').content($step-path);
      $step.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
      $step-list ~= "$step\n";
    }
    $at.at('ol.deriv2').content($step-list);
  }

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
             ,     :@rpath-links
             ,     :@cpath-links
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
                , rpath-links    => @rpath-links
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

Copyright 2022, 2023, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
