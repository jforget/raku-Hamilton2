# -*- encoding: utf-8; indent-tabs-mode: nil -*-

unit package common;

use Template::Anti :one-off;
use map-gd;
use MIME::Base64;
use messages-list;

our sub links($at, :$lang
             ,     :$mapcode
             ,     :%map
             ,     :%region
             ,     :@messages
             ,     :@macro-links
             ,     :@full-links
             ,     :@region-links
             ,     :@canon-links
             , Str :$query-string) {
  $at('h1')».content(%map<name>);
  $at.at('a.full-map-link'  ).attr(href => "/$lang/full-map/$mapcode$query-string");
  $at.at('a.macro-map-link' ).attr(href => "/$lang/macro-map/$mapcode$query-string");
  $at.at('a.macro-stat-link').attr(href => "/$lang/macro-stat/$mapcode$query-string");
  if %region<code>:exists {
    $at.at('a.region-map-link'  ).attr(href => "/$lang/region-map/$mapcode/%region<code>$query-string");
    $at.at('a.region-stat-link' ).attr(href => "/$lang/region-stat/$mapcode/%region<code>$query-string");
    $at.at('a.shpth-region-link').attr(href => "/$lang/shortest-path/region/$mapcode/%region<code>$query-string");
  }
  else {
    $at.at('a.region-map-link'  )».remove;
    $at.at('a.region-stat-link' )».remove;
    $at.at('a.shpth-region-link')».remove;
  }
  if %map<nb_full> != 0 {
    $at.at('a.macro-stat1-link').attr(href => "/$lang/macro-stat1/$mapcode$query-string");
  }
  else {
    $at.at('a.macro-stat1-link')».remove;
  }
  $at.at('a.shpth-macro-link').attr(href => "/$lang/shortest-path/macro/$mapcode$query-string");
  $at.at('a.shpth-full-link' ).attr(href => "/$lang/shortest-path/full/$mapcode$query-string");

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

  if %region<code>:!exists {
    $at.at('div.region-path').content('');
  }
  elsif @region-links.elems eq 0 {
    $at.at('p.list-of-region-paths')».remove;
  }
  else {
    my $links = join ' ', @region-links.map( { "<a href='{$_<link>}'>{$_<txt>}</a>" } );
    $at.at('p.list-of-region-paths').content($links);
    $at.at('p.empty-list-of-region-paths')».remove;
  }

  if @canon-links.elems == 0 {
    $at.at('div.canon')».content('');
  }
  else {
    my Str $region = $mapcode.uc;
    my $links = join ' ', @canon-links.map( { "<a href='/$lang/region-path/$mapcode/$region/$_$query-string'>{$_}</a>" } );
    $at.at('p.list-of-canon-paths').content($links);
  }
  $at.at('ul.messages').content(messages-list::render($lang, @messages));
}
