# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Génération de la page HTML présentant les statistiques sur les chemins hamiltoniens
#     Generating the HTML pages showing stats on Hamiltonian paths
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#
unit package Hamilton-stat;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;
use common;
use Graph:from<Perl5>;

sub fill($at,  :$lang
        ,      :$mapcode
        ,      :%map
        ,      :%region
        , Str  :$from = ''
        , Str  :$to   = ''
        ,      :@areas
        ,      :@borders
        ,      :@messages
        ,      :@macro-links
        ,      :@full-links
        ,      :@region-links
        ,      :@canon-links
        , Str  :$query-string
        , Bool :$variant
        , Bool :$squeeze-zero = False
        ) {

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

  my Str $region-code = %region<code> // '';
  $at('title')».content(%map<name>);
  $at('h1'   )».content(%map<name>);
  if $from ne '' {
    $at('span.from-code')».content($from);
    $at('span.to-code'  )».content($to);
  }
  if $region-code eq '' {
    $at.at('table.node-table tr.small-node-title')».content('');
    $at.at('table.edge-table tr.small-edge-title')».content('');
    $at.at('table.node-table tr.small-node-title')».remove;
    $at.at('table.edge-table tr.small-edge-title')».remove;
  }
  else {
    $at.at('table.node-table tr.big-node-title'  )».content('');
    $at.at('table.edge-table tr.big-edge-title'  )».content('');
    $at.at('table.node-table tr.big-node-title'  )».remove;
    $at.at('table.edge-table tr.big-edge-title'  )».remove;
  }
  unless $variant {
    $at.at('p.variant')».remove;
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
  my %tbl-url-of-area;
  for @areas -> $area {
    if $region-code eq '' || $area<upper> eq $region-code {
      %node-histo{$area<nb_paths_stat>}<nb>++;
      %node-histo{$area<nb_paths_stat>}<nodes>.push($area<code>);
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
    $node-line.at('td.node-list').content(%node-histo{$nb}<nodes>.sort.map({ %tbl-url-of-area{$_} }).join(', '));
    $list ~= "$node-line\n";
  }
  $at.at('table.node-table').append-content($list);

  for @areas -> $area {
    if $region-code ne '' && $area<upper> ne $region-code {
      $area<color> = 'Black';
    }
    else {
      $area<name> ~= ": $area<nb_paths_stat>";
      my $i = @colour-scheme.first( { $_<min> ≤ $area<nb_paths_stat> ≤ $_<max> }, :k);
      $area<color> = @colours[$i];
    }
  }

  my %edge-histo;
  for @borders -> $border {
    if ($region-code eq '' or $border<color> ne 'Black') and $border<code_f> le $border<code_t> {
      %edge-histo{$border<nb_paths_stat>}<nb>++;
      %edge-histo{$border<nb_paths_stat>}<edges>.push("$border<code_f> → $border<code_t>");
    }
  }
  if $squeeze-zero {
    %edge-histo<0>:delete;
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
    if $region-code eq '' or $border<color> ne 'Black' {
      if $squeeze-zero and $border<nb_paths_stat> == 0 {
        $border<color> = 'Black';
        $border<name > = '';
      }
      else {
        my $i = @colour-scheme.first( { $_<min> ≤ $border<nb_paths_stat> ≤ $_<max> }, :k);
        $border<color> = @colours[$i];
        $border<name > = $border<nb_paths_stat>.Str;
      }
    }
  }

  my ($png, Str $imagemap) = map-gd::draw(@areas, @borders, query-string => $query-string, with_scale => %map<with_scale>);

  if %region<code>:!exists {
    $at.at('div.region'         ).content('');
    $at.at('a.region-map-link'  )».remove;
    $at.at('a.region-stat-link' )».remove;
    $at.at('a.shpth-region-link')».remove;
    $at.at('span.fruitless-reason-region')».remove;
  }
  $at.at('img').attr(src => "data:image/png;base64," ~ MIME::Base64.encode($png));
  $at.at('a.macro-map' ).attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('a.macro-stat').attr(href => "/$lang/macro-stat/$mapcode$query-string");
  if %map<nb_full> != 0 {
    $at.at('a.macro-stat1').attr(href => "/$lang/macro-stat1/$mapcode$query-string");
  }
  else {
    $at.at('a.macro-stat1')».remove;
  }
  $at('map')».content($imagemap);

  if %map<fruitless_reason> eq '' {
    $at.at('span.fruitless-reason-macro')».remove;
    $at.at('p.fruitless-macro')».remove;
  }
  else {
    $at.at('span.fruitless-reason-macro').content(%map<fruitless_reason>);
  }

}

our sub render(Str  $lang
             , Str  $map
             ,      :%map
             ,      :%region
             ,      :@areas
             ,      :@borders
             ,      :@messages
             ,      :@macro-links
             ,      :@full-links
             ,      :@region-links
             ,      :@canon-links
             , Str  :$query-string
             , Bool :$variant
             ) {
  my &filling = anti-template :source("html/Hamilton-stat.$lang.html".IO.slurp), &fill;
  return filling(lang         => $lang
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
               , variant      => $variant
               );
}

our sub render-from-to(Str  $lang
                     , Str  $map
                     , Str  :$from
                     , Str  :$to
                     ,      :%map
                     ,      :%region
                     ,      :@areas
                     ,      :@borders
                     ,      :@neighbours
                     ,      :@messages
                     ,      :@macro-links
                     ,      :@full-links
                     ,      :@region-links
                     ,      :@canon-links
                     , Str  :$query-string
                     ) {
  my &filling = anti-template :source("html/shortest-paths-from-to.$lang.html".IO.slurp), &fill;

  my @area-codes = @areas.map( { $_<code> } );
  my %code-ok;
  for @area-codes -> $code {
    %code-ok{$code} = True;
  }
  my @border-codes = gather {
    for @borders -> $border {
      if %code-ok{$border<code_f>} && %code-ok{$border<code_t>} && $border<code_f> lt $border<code_t> {
        take [$border<code_f>, $border<code_t>];
      }
    }
  }

  my $graph = Graph.new(undirected => 1
                      , vertices   => @area-codes
                      , edges      => @border-codes);
  my $apsp = $graph.APSP_Floyd_Warshall;

  # step zero: initialise the statistics for discarded areas, for their borders and for transverse borders
  # the statistics are initialised to zero for the used areas and the used borders, but it does not matter
  my %n1-of-area;
  my %n1-of-border;
  my %n2-of-area;
  my %n2-of-border;
  for @areas -> $area {
    $area<nb_paths_stat> = 0;
    %n1-of-area{$area<code>} = 0;
    %n2-of-area{$area<code>} = 0;
  }
  for @neighbours -> $area {
    $area<nb_paths_stat> = 0;
  }
  for @borders -> $border {
    $border<nb_paths_stat> = 0;
  }

  # first step, compute the total distance
  my Int $dist = $apsp.path_length($from, $to);

  # second step, fill the buckets
  my Array @node-buckets = [] xx ($dist + 1);
  my %bucket-of-node;
  for @area-codes -> $area-code {
    my $d1 = $apsp.path_length($from, $area-code);
    my $d2 = $apsp.path_length($to  , $area-code);
    if $d1 + $d2 == $dist {
      @node-buckets[$d1].push($area-code);
      %bucket-of-node{$area-code} = $d1;
    }
  }
  my @active-borders = gather {
      for @border-codes -> $border-code {
        my Str $b-from = $border-code[0];
        my Str $b-to   = $border-code[1];
        next unless %bucket-of-node{$b-from}:exists; # border from a discarded area
        next unless %bucket-of-node{$b-to  }:exists; # border to   a discarded area
        next if     %bucket-of-node{$b-from} == %bucket-of-node{$b-to}; # transverse border
        if %bucket-of-node{$b-from} < %bucket-of-node{$b-to} {
          take ($b-from, $b-to);
        }
        else {
          take ($b-to, $b-from);
        }
      }
    }

  # Third step, compute n1 for areas and borders
  %n1-of-area{$from} = 1;
  for 1 .. $dist -> $d {
    for @(@node-buckets[$d]) -> $area {
      for @active-borders -> $border-code {
        my Str $b-from = $border-code[0];
        my Str $b-to   = $border-code[1];
        next unless $b-from eq $area or $b-to eq $area;
        if $b-to eq $area {
          %n1-of-border{$b-from}{$b-to} = %n1-of-area{$b-from};
          %n1-of-area{$b-to} += %n1-of-border{$b-from}{$b-to};
        }
      }
    }
  }

  # Fourth step, compute n2 for areas and borders
  %n2-of-area{$to} = %n1-of-area{$to};
  for (0 ..^ $dist).reverse -> $d {
    for @(@node-buckets[$d]) -> $area {
      for @active-borders -> $border-code {
        my Str $b-from = $border-code[0];
        my Str $b-to   = $border-code[1];
        next unless $b-from eq $area or $b-to eq $area;
        if $b-from eq $area {
          %n2-of-border{$b-from}{$b-to} = %n2-of-area{$b-to} × %n1-of-border{$b-from}{$b-to} / %n1-of-area{$b-to};
          %n2-of-area{$b-from} += %n2-of-border{$b-from}{$b-to};
        }
      }
    }
  }

  # Conclusion, filling the statistics
  for @areas -> $area {
    if %n2-of-area{$area<code>}:exists {
      $area<nb_paths_stat> =  %n2-of-area{$area<code>}.Int;
    }
  }
  for @borders -> $border {
    my $code_f = $border<code_f>;
    my $code_t = $border<code_t>;
    if %n2-of-border{$code_f}{$code_t}:exists {
      $border<nb_paths_stat> =  %n2-of-border{$code_f}{$code_t}.Int;
    }
    if %n2-of-border{$code_t}{$code_f}:exists {
      $border<nb_paths_stat> =  %n2-of-border{$code_t}{$code_f}.Int;
    }
  }

  @areas.append(@neighbours);
  return filling(lang         => $lang
               , mapcode      => $map
               , map          => %map
               , region       => %region
               , from         => $from
               , to           => $to
               , areas        => @areas
               , borders      => @borders
               , messages     => @messages
               , macro-links  => @macro-links
               , full-links   => @full-links
               , region-links => @region-links
               , canon-links  => @canon-links
               , query-string => $query-string
               , variant      => False
               , squeeze-zero => True
               );
}


=begin POD

=encoding utf8

=head1 NAME

Hamilton-stat.rakumod -- utility module to show statistics on Hamiltonian paths

=head1 DESCRIPTION

This module  builds the  HTML file  rendering a  map available  in the
Hamilton SQLite database. It is used internally by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, 2023, 2024 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the license is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
