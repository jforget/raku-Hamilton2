# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML détaillant une carte de la base de données Hamilton.db
#     Generating the HTML pages rendering a map from the Hamilton.db database
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package macro-stat;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

sub fill($at, :$lang
        ,     :$mapcode
        ,     :%map
        ,     :@areas
        ,     :@borders
        ,     :@messages
        ,     :@macro-links
        ,     :@full-links
        ,     :@ico-links
        , Str :$query-string) {
  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);

  $at.at('a.full-map' ).attr(href => "/$lang/full-map/$mapcode$query-string");
  $at.at('a.macro-map').attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('ul.messages').content(messages-list::render($lang, @messages));
  if %map<nb_full> != 0 {
    $at.at('a.macro-stat1').attr(href => "/$lang/macro-stat1/$mapcode$query-string");
  }
  else {
    $at.at('a.macro-stat1')».remove;
  }

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

  my @colour-scheme;
  my @colours-full = <Blue Cyan Green Chartreuse Yellow1 Orange Pink Red>;
  my @colours-part = <Blue Green Yellow Red>;

  my %node-histo;
  for @areas -> $area {
    %node-histo{$area<nb_macro_paths>}<nb>++;
    %node-histo{$area<nb_macro_paths>}<nodes>.push($area<code>);
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
    my $i = @colour-scheme.first( { $_<min> ≤ $nb ≤ $_<max> }, :k);
    my $mime-png = MIME::Base64.encode(%palette{@colours[$i]});
    $node-line.at('td.node-col img').attr(src => "data:image/png;base64," ~ $mime-png);
    $node-line.at('td.node-nb'  ).content($nb);
    $node-line.at('td.node-list').content(%node-histo{$nb}<nodes>.join(', '));
    $list ~= "$node-line\n";
  }
  $at.at('table.node-table').append-content($list);

  for @areas -> $area {
    $area<name> ~= ": $area<nb_macro_paths>";
    my $i = @colour-scheme.first( { $_<min> ≤ $area<nb_macro_paths> ≤ $_<max> }, :k);
    $area<color> = @colours[$i];
  }

  my %edge-histo;
  for @borders -> $border {
    if $border<code_f> lt $border<code_t> {
      %edge-histo{$border<nb_paths>}<nb>++;
      %edge-histo{$border<nb_paths>}<edges>.push("$border<code_f> → $border<code_t>");
    }
  }
  if %edge-histo.keys.elems ≤ @colours-part.elems {
    @colours = @colours-part;
  }
  else {
    @colours = @colours-full;
  }
  $colour-max = @colours.elems;
  %palette    = map-gd::palette-sample(@colours);

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
    my $i = @colour-scheme.first( { $_<min> ≤ $nb ≤ $_<max> }, :k);
    my $mime-png = MIME::Base64.encode(%palette{@colours[$i]});
    $edge-line.at('td.edge-col img').attr(src => "data:image/png;base64," ~ $mime-png);
    $edge-line.at('td.edge-nb'  ).content($nb);
    $edge-line.at('td.edge-list').content(%edge-histo{$nb}<edges>.join(', '));
    $list ~= "$edge-line\n";
  }
  $at.at('table.edge-table').append-content($list);

  for @borders -> $border {
    my $i = @colour-scheme.first( { $_<min> ≤ $border<nb_paths> ≤ $_<max> }, :k);
    $border<color> = @colours[$i];
    $border<name > = $border<nb_paths>.Str;
  }
  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, query-string => $query-string);
  $at('map')».content($imagemap);
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));

  if %map<fruitless_reason> eq '' {
    $at.at('span.fruitless-reason')».remove;
    $at.at('p.fruitless')».remove;
  }
  else {
    $at.at('span.fruitless-reason').content(%map<fruitless_reason>);
  }

  if @macro-links.elems eq 0 {
    $at.at('p.list-of-macro-paths')».remove;
  }
  else {
    for @macro-links <-> $macro {
      if $macro<bold> {
        $macro<txt> = "<b>{$macro<txt>}</b>";
      }
    }
    my $links = join ' ', @macro-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
    $at.at('p.list-of-macro-paths').content($links);
    $at.at('p.empty-list-of-macro-paths')».remove;
  }

  if @full-links.elems eq 0 {
    $at.at('p.list-of-full-paths')».remove;
  }
  else {
    my $links = join ' ', @full-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
    $at.at('p.list-of-full-paths').content($links);
    $at.at('p.empty-list-of-full-paths')».remove;
  }

  if @ico-links.elems == 0 {
    $at.at('div.ico')».content('');
  }
  else {
    my $links = join ' ', @ico-links.map( { "<a href='/$lang/region-path/ico/ICO/$_$query-string'>{$_}</a>" } );
    $at.at('p.list-of-ico-paths').content($links);
  }

}

our sub render(Str $lang
            , Str  $map
            ,      %map
            ,     :@areas
            ,     :@borders
            ,     :@messages
            ,     :@macro-links
            ,     :@full-links
            ,     :@ico-links
            , Str :$query-string) {
  my &filling = anti-template :source("html/macro-stat.$lang.html".IO.slurp), &fill;
  return filling( lang         => $lang
                , mapcode      => $map
                , map          => %map
                , areas        => @areas
                , borders      => @borders
                , messages     => @messages
                , macro-links  => @macro-links
                , full-links   => @full-links
                , ico-links    => @ico-links
                , query-string => $query-string
                );
}


=begin POD

=encoding utf8

=head1 NAME

map-page.rakumod -- utility module to render a map.

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
