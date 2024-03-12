# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant les statistiques sur les plus courts chemoins
#     Generating the HTML pages rendering a map with statistics on shortest paths
#     Copyright (C) 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package shortest-path-stat;

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

  my Int $nb-areas = @areas.elems;
  $at.at('span.path-number')».content(%map<nb_macro>.Str);
  $at.at('span.node-number')».content($nb-areas.Str);
  $at.at('span.edge-number')».content((%map<nb_macro> × ($nb-areas - 1)).Str);
  if $nb-areas == 1 {
    # only one area, only one Hamiltonian macro-path in which the beginning and the end are located on the same node
    $at.at('span.start-stop-number')».content('1');
  }
  else {
    $at.at('span.start-stop-number')».content(2 × %map<nb_macro>.Str);
  }

  my Int $diameter = %region<diameter> // %map<diameter> // 999;
  my Int $radius   = %region<radius  > // %map<radius  > // 999;
  if $diameter ≥ 0 {
    $at.at('span.diameter')».content($diameter.Str);
  }
  if $radius ≥ 0 {
    $at.at('span.radius')».content($radius.Str);
  }
  my @colour-scheme;
  my @colours-full = <Blue Cyan Green Chartreuse Yellow1 Orange Red>;
  my @colours-part = <Blue Green Yellow Red>;

  my %node-histo;
  my %tbl-url-of-area;
  for @areas -> $area {
    if $area<stat>:exists {
      %node-histo{$area<stat>}<nb>++;
      %node-histo{$area<stat>}<nodes>.push($area<code>);
      if $area<tbl-url>:exists {
        %tbl-url-of-area{$area<code>} = "<a href='{$area<tbl-url>}'>{$area<code>}</a>";
      }
      else {
        %tbl-url-of-area{$area<code>} = $area<code>;
      }
    }
  }
  my @colours;
  if %node-histo.keys.elems ≤ @colours-part.elems {
    @colours = @colours-part;
  }
  else {
    @colours = @colours-full;
  }
  my $colour-max = @colours.elems;
  my %palette    = map-gd::palette-sample(@colours);

  my Int $low-stat = %node-histo.keys.map( { $_.Int } ).min;
  my Str $list = '';
  my $node-line = $at.at('table.node-table tr.node-line');
  $at('table.node-table tr.node-line')».remove;
  for %node-histo.keys.sort( { $^a <=> $^b }) -> $nb {
    my $mime-png;
    if 0 ≤ $nb < @areas.elems {
      my Int $i = ($nb - $low-stat) % $colour-max;
      $mime-png = MIME::Base64.encode(%palette{@colours[$i]});
      $node-line.at('td.node-nb').content($nb);
    }
    else {
      $mime-png = MIME::Base64.encode(%palette<Red>);
      $node-line.at('td.node-nb').content('∞');
    }
    $node-line.at('td.node-col img').attr(src => "data:image/png;base64," ~ $mime-png);
    my @content;
    $node-line.at('td.node-list').content(%node-histo{$nb}<nodes>.sort.map({ %tbl-url-of-area{$_} }).join(', '));
    $list ~= "$node-line\n";
  }
  $at.at('table.node-table').append-content($list);

  my %colour-of-area;
  for @areas -> $area {
    if $area<stat>:exists {
      if 0 ≤ $area<stat> < @areas.elems {
        $area<color> = @colours[($area<stat> - $low-stat) % $colour-max];
        $area<name> ~= ": $area<stat>";
      }
      else {
        $area<name> ~= ": ∞";
        $area<color> = 'Red';
      }
    }
    else {
      $area<color> = 'Black';
    }
    %colour-of-area{$area<code>} = $area<color>;
  }

  for @borders -> $border {
    if %colour-of-area{$border<code_f>} eq %colour-of-area{$border<code_t>} {
      $border<color> = %colour-of-area{$border<code_f>};
    }
    else {
      $border<color> = 'Black';
    }
  }
  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, query-string => $query-string, with_scale => %map<with_scale>);
  $at('map')».content($imagemap);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));

  if %map<fruitless_reason> eq '' {
    $at.at('span.fruitless-reason')».remove;
    $at.at('p.fruitless')».remove;
  }
  else {
    $at.at('span.fruitless-reason').content(%map<fruitless_reason>);
  }

}

our sub render(Str $lang
             , Str  $map
             ,      %map
             ,      %region
             ,     :@areas
             ,     :@borders
             ,     :@messages
             ,     :@macro-links
             ,     :@full-links
             ,     :@region-links
             ,     :@canon-links
             , Str :$query-string) {
  my &filling = anti-template :source("html/shortest-path-stat.$lang.html".IO.slurp), &fill;
  return filling( lang         => $lang
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

our sub render-from(Str $lang
                  , Str  $map
                  ,      %map
                  ,      %region
                  ,     :@areas
                  ,     :@borders
                  ,     :@messages
                  ,     :@macro-links
                  ,     :@full-links
                  ,     :@region-links
                  ,     :@canon-links
                  , Str :$query-string) {
  my &filling = anti-template :source("html/shortest-paths-from.$lang.html".IO.slurp), &fill;
  return filling( lang         => $lang
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

shortest-path-stat.rakumod -- utility module to render a map.

=head1 DESCRIPTION

This module  builds the  HTML file  rendering a  map available  in the
Hamilton SQLite database. It is used internally by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, 2023, 2024 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
