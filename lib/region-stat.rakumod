# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant une carte de la base de données Hamilton.db
#     Generating the HTML pages rendering a map from the Hamilton.db database
#     Copyright (C) 2022, 2023 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package region-stat;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang, :$mapcode, :%map, :%region, :@areas, :@borders, :@messages
        ,     :@path-links
        ,     :@ico-links
        , Str :$query-string) {
  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);
  $at('span.region-name')».content(%region<name>);

  my Int $nb-areas = @areas.grep( { $_<upper> eq %region<code> } ).elems;
  $at.at('span.path-number')».content(%region<nb_region_paths>.Str);
  $at.at('span.node-number')».content($nb-areas.Str);
  $at.at('span.edge-number')».content((%region<nb_region_paths> × ($nb-areas - 1)).Str);
  if $nb-areas == 1 {
    # only one area, only one Hamiltonian regional path in which the beginning and the end are located on the same node
    $at.at('span.start-stop-number')».content('1');
  }
  else {
    $at.at('span.start-stop-number')».content(2 × %region<nb_region_paths>.Str);
  }

  my @colour-scheme;
  my @colours    = <Blue Cyan Green Chartreuse Yellow1 Orange Pink Red>;
  my $colour-max = @colours.elems;

  my %node-histo;
  for @areas -> $area {
    if $area<upper> eq %region<code> {
      %node-histo{$area<nb_region_paths>}<nb>++;
      %node-histo{$area<nb_region_paths>}<nodes>.push($area<code>);
    }
  }

  my Str $list = '';
  my $node-line = $at.at('table.node-table tr.node-line');
  for %node-histo.keys.sort( { $^a <=> $^b }) -> $nb {
    @colour-scheme.push( %( min => $nb, max => $nb, nb => %node-histo{$nb}<nodes>.elems ) );
  }
  while @colour-scheme.elems > $colour-max {
    my Int $nb-min = 999_999_999;
    my Int $idx-min;
    loop (my $i = 0; $i < @colour-scheme.elems - 1; $i++) {
      my $nb = @colour-scheme[$i]<nb> + @colour-scheme[$i + 1]<nb>;
      if $nb < $nb-min {
        $nb-min  = $nb;
        $idx-min = $i;
      }
    }
    @colour-scheme[$idx-min]<max>  = @colour-scheme[$idx-min + 1]<max>;
    @colour-scheme[$idx-min]<nb > += @colour-scheme[$idx-min + 1]<nb >;
    splice(@colour-scheme, $idx-min + 1, 1);
  }
  $at('table.node-table tr.node-line')».remove;
  for %node-histo.keys.sort( { $^a <=> $^b }) -> $nb {
    $node-line.at('td.node-nb'  ).content($nb);
    $node-line.at('td.node-list').content(%node-histo{$nb}<nodes>.join(', '));
    $list ~= "$node-line\n";
  }
  $at.at('table.node-table').append-content($list);

  for @areas -> $area {
    if $area<upper> ne %region<code> {
      $area<color> = 'Black';
    }
    else {
      $area<name> ~= ": $area<nb_region_paths>";
      my $i = @colour-scheme.first( { $_<min> ≤ $area<nb_region_paths> ≤ $_<max> }, :k);
      $area<color> = @colours[$i];
    }
  }

  my %edge-histo;
  for @borders -> $border {
    if $border<color> ne 'Black' and $border<code_f> lt $border<code_t> {
      %edge-histo{$border<nb_paths>}<nb>++;
      %edge-histo{$border<nb_paths>}<edges>.push("$border<code_f> → $border<code_t>");
    }
  }

  @colour-scheme = ();
  for %edge-histo.keys.sort( { $^a <=> $^b }) -> $nb {
    @colour-scheme.push( %( min => $nb, max => $nb, nb => %edge-histo{$nb}<nodes>.elems ) );
  }
  while @colour-scheme.elems > $colour-max {
    my Int $nb-min = 999_999_999;
    my Int $idx-min;
    loop (my $i = 0; $i < @colour-scheme.elems - 1; $i++) {
      my $nb = @colour-scheme[$i]<nb> + @colour-scheme[$i + 1]<nb>;
      if $nb < $nb-min {
        $nb-min  = $nb;
        $idx-min = $i;
      }
    }
    @colour-scheme[$idx-min]<max>  = @colour-scheme[$idx-min + 1]<max>;
    @colour-scheme[$idx-min]<nb > += @colour-scheme[$idx-min + 1]<nb >;
    splice(@colour-scheme, $idx-min + 1, 1);
  }

  $list = '';
  my $edge-line = $at.at('table.edge-table tr.edge-line');
  $at('table.edge-table tr.edge-line')».remove;
  for %edge-histo.keys.sort( { $^a <=> $^b }) -> $nb {
    $edge-line.at('td.edge-nb'  ).content($nb);
    $edge-line.at('td.edge-list').content(%edge-histo{$nb}<edges>.join(', '));
    $list ~= "$edge-line\n";
  }
  $at.at('table.edge-table').append-content($list);

  for @borders -> $border {
    if $border<color> ne 'Black' {
      my $i = @colour-scheme.first( { $_<min> ≤ $border<nb_paths> ≤ $_<max> }, :k);
      $border<color> = @colours[$i];
      $border<name > = $border<nb_paths>.Str;
    }
  }

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, query-string => $query-string);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at.at('a.full-map'   ).attr(href => "/$lang/full-map/$mapcode$query-string");
  $at.at('a.macro-map'  ).attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('a.macro-stat' ).attr(href => "/$lang/macro-stat/$mapcode$query-string");
  $at.at('a.region-map' ).attr(href => "/$lang/region-map/$mapcode/%region<code>$query-string");
  $at.at('a.region-stat').attr(href => "/$lang/region-stat/$mapcode/%region<code>$query-string");
  $at('map')».content($imagemap);

  if @path-links.elems eq 0 {
    $at.at('p.list-of-region-paths')».remove;
  }
  else {
    my $links = join ' ', @path-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
    $at.at('p.list-of-region-paths').content($links);
    $at.at('p.empty-list-of-region-paths')».remove;
  }

  if @ico-links.elems == 0 {
    $at.at('div.ico')».content('');
  }
  else {
    my $links = join ' ', @ico-links.map( { "<a href='/$lang/region-path/ico/ICO/$_$query-string'>{$_}</a>" } );
    $at.at('p.list-of-ico-paths').content($links);
  }

  $at.at('ul.messages').content(messages-list::render($lang, @messages));
}

our sub render(Str $lang, Str $map, %map, :%region, :@areas
            ,     :@borders
            ,     :@messages
            ,     :@path-links
            ,     :@ico-links
            , Str :$query-string) {
  my &filling = anti-template :source("html/region-stat.$lang.html".IO.slurp), &fill;
  return filling( lang         => $lang
                , mapcode      => $map
                , map          => %map
                , region       => %region
                , areas        => @areas
                , borders      => @borders
                , messages     => @messages
                , path-links   => @path-links
                , ico-links    => @ico-links
                , query-string => $query-string
                );
}


=begin POD

=encoding utf8

=head1 NAME

region-map.rakumod -- utility module to render a map.

=head1 DESCRIPTION

This module  builds the  HTML file  rendering a  map available  in the
Hamilton SQLite database. It is used internally by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, 2023, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
