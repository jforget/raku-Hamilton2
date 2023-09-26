# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération graphique d'une carte (macro, complète ou régionale)
#     Graphical generation of a map (macro, full or regional)
#     Copyright (C) 2022, 2023 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

unit package map-gd;

use GD:from<Perl5>;
use List::Util;
use PostCocoon::Url;
use db-conf-sql;

our sub draw(@areas, @borders, Str :$path = '', Str :$query-string = '') {
  my $height = height-from-query($query-string) || picture-height;
  my $width  =  width-from-query($query-string) || picture-width;
  my Int $dim-scale =  20;
  my Int $lg-max    = ($width / 2).Int;

  my $image = GD::Image.new($width + $dim-scale, $height + $dim-scale);
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
  if $char-max == 1 {
    # If $char-max is 1, it reflects the widths of the strings, but not their heights which is a bit more.
    $char-max = 2;
  }
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
  my Num $delta-long = 1e-3 max ($long-max - $long-min); # 1e-3 to prevent a division by zero if $long-max == $long-min
  my Num $delta-lat  = 1e-3 max ( $lat-max -  $lat-min);

  sub conv-x(Num $long) { return ($margin + ($long - $long-min) / $delta-long × ($width  - 2 × $margin)).Int };
  sub conv-y(Num $lat ) { return ($margin + ($lat-max   - $lat) / $delta-lat  × ($height - 2 × $margin)).Int };

  my $scale-distance;
  my $top-scale;
  loop ($scale-distance = 10_000; $scale-distance > 0.001; $scale-distance /= 10) {
    # 111 : the length (in kilometers) of a degree of latitude, either 60 nautical miles at 1852 m each, or 10_000 km divided by 90
    $top-scale =  conv-y($lat-min + $scale-distance / 111);
    last if conv-y($lat-min) - $top-scale < $lg-max;
  }
  my $scale-label = "$scale-distance km";
  my $x-scale     = $width + $dim-scale - 6 × $scale-label.chars;
  $image.line($width, conv-y($lat-min), $width, $top-scale, $black);
  $image.string(gdSmallFont, $x-scale, $top-scale - 20, $scale-label, $black);

  my $left-scale;
  # 111 : the length (in kilometers) of a degree of latitude, either 60 nautical miles at 1852 m each, or 10_000 km divided by 90
  # but for a degree of longitude, the length is shorter, because of latitude
  my $length-of-one-degree = 111 × cos(pi / 180 × ($lat-max + $lat-min) / 2);
  loop ($scale-distance = 10_000; $scale-distance > 0.001; $scale-distance /= 10) {
    $left-scale =  conv-x($long-max - $scale-distance / $length-of-one-degree);
    last if conv-x($long-max) - $left-scale < $lg-max;
  }
  $scale-label = "$scale-distance km";
  $x-scale     = $left-scale - 6 × $scale-label.chars;
  $image.line($left-scale, $height + $dim-scale / 2, conv-x($long-max), $height + $dim-scale / 2, $black);
  $image.string(gdSmallFont, $x-scale, $height, $scale-label, $black);

  my Str $imagemap = '';

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
    if   $path.contains(" $sub-path1 ") or $path.starts-with($sub-path1) or $path.ends-with($sub-path1)
      or $path.contains(" $sub-path2 ") or $path.starts-with($sub-path2) or $path.ends-with($sub-path2) {
      $thickness = 3;
    }

    $imagemap ~= draw-border($image, $xf, $yf, $xm, $ym, $xt, $yt, %color{$border<color>}, $border<color>, $thickness, $border<fruitless>, $border<name> // '');
  }

  for @areas -> $area {
    my Int $x = conv-x($area<long>.Num);
    my Int $y = conv-y($area<lat >.Num);
    #say join ' ', $area<code>, $area<long>, $area<lat>, $x, $y;
    $imagemap ~= draw-area($image, $x, $y, $area<code>, $white, $black, %color{$area<color>}, $area<url>, $area<name>);
  }

  return $image.png(), $imagemap;
}

sub draw-border($img, Int $x-from, Int $y-from
                    , Int $x-mid is copy
                    , Int $y-mid is copy
                    , Int $x-to
                    , Int $y-to
                    , $color
                    , Str $color-name
                    , Int $thickness
                    , Int $fruitless
                    , Str $name) {
  my $title-text = '';
  my $style;
  if $fruitless {
    $img.setStyle($color, $color, gdTransparent, gdTransparent);
    $style = gdStyled;
  }
  else {
    $style = $color;
  }
  $img.setThickness($thickness);
  if $x-mid == 0 && $y-mid == 0 {
    $img.line($x-from, $y-from, $x-to , $y-to , $style);
    if $color-name eq 'Black' {
      $img.filledEllipse( ($x-from + $x-to) / 2, ($y-from + $y-to) / 2, 4 × $thickness, 4 × $thickness, $color);
    }
    $x-mid = (($x-from + $x-to) / 2).Int;
    $y-mid = (($y-from + $y-to) / 2).Int;
  }
  else {
    $img.line($x-from, $y-from, $x-mid, $y-mid, $style);
    $img.line($x-mid , $y-mid , $x-to , $y-to , $style);
    if $color-name eq 'Black' {
      # do not bother to compute the middle of the line, just use the turning point
      $img.filledEllipse( $x-mid, $y-mid, 4 × $thickness, 4 × $thickness, $color);
    }
  }
  if $name ne '' {
    $img.filledRectangle( $x-mid - 2 × $thickness
                        , $y-mid - 2 × $thickness
                        , $x-mid + 2 × $thickness
                        , $y-mid + 2 × $thickness
                        , $color);
    $title-text = "<area coords='{$x-mid - 2 × $thickness}"
                             ~ ",{$y-mid - 2 × $thickness}"
                             ~ ",{$x-mid + 2 × $thickness}"
                             ~ ",{$y-mid + 2 × $thickness}"
                             ~ "' title='$name'>\n";

  }
  return $title-text;
}

sub draw-area($img, Int $x, Int $y, Str $txt, $backg, $ink, $color, Str $url, Str $name is copy) {
  my ($dx, $dy) = ( 2.5 × $txt.chars,  5);
  my Int $radius   =  5 × $txt.chars;
  if $radius < 10 {
    # If $radius is 5, it reflects the half-width of the one-char string, but not its half-height which is a bit more.
    $radius = 10;
  }
  my Int $diameter =  2 × $radius;
  $img.setThickness(3);
  $img.filledEllipse($x, $y, $diameter, $diameter, $backg);
  $img.ellipse(      $x, $y, $diameter, $diameter, $color);
  $img.setThickness(1);
  $img.string(gdSmallFont, $x - $dx, $y - $dy, $txt, $ink);
  $name ~~ s:g/\'/\&\#039;/;
  if $url eq '' {
    return "<area shape='circle' coords='$x,$y,$radius' title='$name' />\n";
  }
  else {
    return "<area shape='circle' coords='$x,$y,$radius' href='$url' title='$name' />\n";
  }
}

sub param-from-query(Str $query-string is copy, Str $key) {
  if $query-string.substr(0, 1) eq '?' {
    $query-string .= substr(1);
  }
  my %param = parse-query-string(url-decode($query-string));
  return %param{$key} // '';
}

sub width-from-query(Str $query-string) {
  param-from-query($query-string, 'w');
}

sub height-from-query(Str $query-string) {
  param-from-query($query-string, 'h');
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

Copyright 2022, 2023, Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
