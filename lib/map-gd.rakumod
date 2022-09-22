# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération graphique d'une carte (macro, complète ou régionale)
#     Graphical generation of a map (macro, full or regional)
#     Copyright (C) 2022 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

unit package map-gd;

use GD:from<Perl5>;
use List::Util;

our sub draw(@areas, @borders, :$path = '') {
  my Int $dim       = 1000;
  my Int $dim-scale =   20;
  my $image = GD::Image.new($dim + $dim-scale, $dim + $dim-scale);
  my Int $lg-max = 500;

  my $white  = $image.colorAllocate(255, 255, 255);
  my $black  = $image.colorAllocate(  0,   0,   0);
  my %color;
  %color<Black > = $black;
  %color<Red   > = $image.colorAllocate(255,   0,   0);
  %color<Green > = $image.colorAllocate(  0, 191,   0);
  %color<Blue  > = $image.colorAllocate(  0,   0, 255);
  %color<Yellow> = $image.colorAllocate(223, 150,  23);

  my Num $long-min = min map { $_<long> }, @areas;
  my Num $long-max = max map { $_<long> }, @areas;
  my Num $lat-min  = min map { $_<lat>  }, @areas;
  my Num $lat-max  = max map { $_<lat>  }, @areas;
  my Int $char-max = max map { $_<code>.chars }, @areas;
  my Int $margin   = 6 × $char-max;

  for @borders -> $border {
    # Is there a middle point with an extreme longitude or latitude?
    if $border<long_m> != 0 or $border<lat_m> != 0 {
      my $long-m = $border<long_m>.Num;
      my $lat-m  = $border<lat_m >.Num;
      $long-min = $long-m if $long-m < $long-min;
      $long-max = $long-m if $long-m > $long-max;
      $lat-min  = $lat-m  if $lat-m  < $lat-min;
      $lat-max  = $lat-m  if $lat-m  > $lat-max;
    }
  }

  sub conv-x(Num $long) { return ($margin + ($long - $long-min) / ($long-max - $long-min) × ($dim - 2 × $margin)).Int };
  sub conv-y(Num $lat ) { return ($margin + ($lat-max   - $lat) / ($lat-max  -  $lat-min) × ($dim - 2 × $margin)).Int };

  my $scale-distance;
  my $top-scale;
  loop ($scale-distance = 10_000; $scale-distance > 0.001; $scale-distance /= 10) {
    $top-scale =  conv-y($lat-min + $scale-distance / 111);
    last if conv-y($lat-min) - $top-scale < $lg-max;
  }
  my $scale-label = "$scale-distance km";
  my $x-scale     = $dim + $dim-scale - 6 × $scale-label.chars;
  $image.line($dim, conv-y($lat-min), $dim, $top-scale, $black);
  $image.string(gdSmallFont, $x-scale, $top-scale - 20, $scale-label, $black);

  my $left-scale;
  my $length-of-one-degree = 111 × cos(pi / 180 × ($lat-max + $lat-min) / 2);
  loop ($scale-distance = 10_000; $scale-distance > 0.001; $scale-distance /= 10) {
    $left-scale =  conv-x($long-max - $scale-distance / $length-of-one-degree);
    last if conv-x($long-max) - $left-scale < $lg-max;
  }
  $scale-label = "$scale-distance km";
  $x-scale     = $left-scale - 6 × $scale-label.chars;
  $image.line($left-scale, $dim + $dim-scale / 2, conv-x($long-max), $dim + $dim-scale / 2, $black);
  $image.string(gdSmallFont, $x-scale, $dim, $scale-label, $black);


  for @borders -> $border {
    my Int $xf = conv-x($border<long_f>.Num);
    my Int $yf = conv-y($border<lat_f >.Num);
    my Int $xt = conv-x($border<long_t>.Num);
    my Int $yt = conv-y($border<lat_t >.Num);

    # Is there a middle point?
    my Int $xm = 0;
    my Int $ym = 0;
    if $border<long_m> != 0 or $border<lat_m> != 0 {
      $xm = conv-x($border<long_m>.Num);
      $ym = conv-y($border<lat_m >.Num);
    }
    # does the border belong to the path (if any)?
    my Int $thickness = 1;
    my Str $sub-path1 = "{$border<code_f>} → {$border<code_t>}";
    my Str $sub-path2 = "{$border<code_t>} → {$border<code_f>}";
    if $path.contains($sub-path1) or $path.contains($sub-path2) {
      $thickness = 3;
    }

    draw-border($image, $xf, $yf, $xm, $ym, $xt, $yt, %color{$border<color>}, $border<color>, $thickness);
  }

  my Str $imagemap = '';
  for @areas -> $area {
    my Int $x = conv-x($area<long>.Num);
    my Int $y = conv-y($area<lat >.Num);
    #say join ' ', $area<code>, $area<long>, $area<lat>, $x, $y;
    $imagemap ~= draw-area($image, $x, $y, $area<code>, $white, $black, %color{$area<color>}, $area<url>);
  }

  return $image.png(), $imagemap;
}

sub draw-border($img, Int $x-from, Int $y-from, Int $x-mid, Int $y-mid, Int $x-to, Int $y-to, $color, Str $color-name, Int $thickness) {
  $img.setThickness($thickness);
  if $x-mid == 0 && $y-mid == 0 {
    $img.line($x-from, $y-from, $x-to , $y-to , $color);
    if $color-name eq 'Black' {
      $img.filledEllipse( ($x-from + $x-to) / 2, ($y-from + $y-to) / 2, 4 × $thickness, 4 × $thickness, $color);
    }
  }
  else {
    $img.line($x-from, $y-from, $x-mid, $y-mid, $color);
    $img.line($x-mid , $y-mid , $x-to , $y-to , $color);
    if $color-name eq 'Black' {
      # do not bother to compute the middle of the line, just use the turning point
      $img.filledEllipse( $x-mid, $y-mid, 4 × $thickness, 4 × $thickness, $color);
    }
  }
}

sub draw-area($img, Int $x, Int $y, Str $txt, $backg, $ink, $color, Str $url) {
  my ($dx, $dy) = ( 2.5 × $txt.chars,  5);
  my Int $radius   =  5 × $txt.chars;
  my Int $diameter = 10 × $txt.chars;
  $img.setThickness(3);
  $img.filledEllipse($x, $y, $diameter, $diameter, $backg);
  $img.ellipse(      $x, $y, $diameter, $diameter, $color);
  $img.setThickness(1);
  $img.string(gdSmallFont, $x - $dx, $y - $dy, $txt, $ink);
  if $url eq '' {
    return '';
  }
  else {
    return "<area shape='circle' coords='$x,$y,$radius' href='$url' />\n";
  }
}

=begin POD

=encoding utf8

=head1 NAME

map-gd.rakumod -- utility module to generate a PNG objet for a map

=head1 DESCRIPTION

This module deals with graphical  stuff when displaying a macro-map, a
full map  or a regional  map from  the Hamilton database.  This module
returns two values. The  first one is the PNG objet.  The other is the
C<imagemap> HTML source to link  to webpages displaying regional maps.
This module is used by most modules called by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
