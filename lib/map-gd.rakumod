# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération graphique d'une carte (macro, complète ou régionale)
#     Graphical generation of a map (macro, full or regional)
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

unit package map-gd;

use GD:from<Perl5>;
use List::Util;
use PostCocoon::Url;
use db-conf-sql;

sub colors {
  my %color = Black      => [  0,   0,   0]
            , Blue       => [  0,   0, 255]
            , Cyan       => [  0, 255, 255]
            , Green      => [  0, 191,   0]
            , Chartreuse => [127, 255,   0]
            , Yellow     => [223, 150,  23] # darkish, poor contrast with Orange
            , Yellow1    => [255, 255,   0] # light, good contrast with Orange
            , Orange     => [255, 127,   0]
            , Pink       => [255,  79,   0] # poor contrast with Orange and with Red
            , Red        => [255,   0,   0];
  return %color;
}

our sub palette-sample(@palette) {
  my Int $size = sample-size;
  my %samples;
  my %color = colors();
  for @palette -> $palette {
    my $sample = GD::Image.new($size, $size);
    $sample.colorAllocate(|%color{$palette});
    %samples{$palette} = $sample.png;
  }
  return %samples;
}

our sub draw(@areas, @borders
           , Str :$path = ''
           , Str :$query-string = ''
           ,     :%query-params = %()
           , Int :$with_scale = 1) {
  my $height = %query-params<h>   || height-from-query($query-string) || picture-height;
  my $width  = %query-params<w>   ||  width-from-query($query-string) || picture-width;
  my $adjust = %query-params<adj> || adjust-from-query($query-string) || 'nothing';
  my Int $dim-scale =  20;
  my Int $lg-max    = ($width / 2).Int;
  #say "h $height w $width adj $adjust str $query-string hash {%query-params.raku}";

  my %long-of-relay;       # longitude of the relay point of the cross_idl border
  my %lat-of-relay;        #  latitude of the relay point of the cross_idl border
  my %must-display-main;   # Boolean to tell whether the main image must be displayed
  my @longitudes;          # longitudes of all displayed areas excluding hidden areas

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
      @longitudes.push($long-m);
      $lat-min = $lat-m if $lat-m < $lat-min;
      $lat-max = $lat-m if $lat-m > $lat-max;
    }
    # crossing the international date line?
    if $border<cross_idl> == 0 {
      # not crossing: the main images of both areas must be displayed
      %must-display-main{$border<code_f>} = True;
      %must-display-main{$border<code_t>} = True;
    }
    else {
      # crossing the IDL: the main image of the "from" area must be displayed,
      # but the main image of the "to" area may be hidden, unless there is another reason to display it.
      %must-display-main{$border<code_f>} = True;
      %must-display-main{$border<code_t>} //= False;
      %long-of-relay{    $border<code_t>} = $border<long_m>;
       %lat-of-relay{    $border<code_t>} = $border<lat_m >;
      @longitudes.push($border<long_m>);
    }
  }
  for @areas -> $area {
    %must-display-main{$area<code>} //= True;
    if %must-display-main{$area<code>} {
      @longitudes.push($area<long>);
    }
  }
  my Num $long-min = min @longitudes;
  my Num $long-max = max @longitudes;
  my Num $delta-long = 1e-6 max ($long-max - $long-min); # 1e-6 to prevent a division by zero if $long-max == $long-min
  my Num $delta-lat  = 1e-6 max ( $lat-max -  $lat-min); # and 1e-6 degree is about 0.11 meter

  my Num $coef-x  = ($width  - 2 × $margin) / $delta-long;
  my Num $coef-y  = ($height - 2 × $margin) / $delta-lat;
  my Num $mid-lat = π / 180 × ($lat-max + $lat-min) / 2; # medium latitude in radians
  if $with_scale != 1 {
    $mid-lat = 0e0; # so its cosinus is 1
  }

  given $adjust {
    when 'h' {
      $width  = ($width × $coef-y × cos($mid-lat) / $coef-x + 2 × $margin).Int;
      $coef-x = $coef-y × cos($mid-lat);
    }
    when 'w' {
      $height = ($height × $coef-x / ($coef-y × cos($mid-lat)) + 2 × $margin).Int;
      $coef-y = $coef-x / cos($mid-lat);
    }
    when 'min' {
      if $coef-x > $coef-y × cos($mid-lat) {
        $width  = ($width × $coef-y × cos($mid-lat) / $coef-x + 2 × $margin).Int;
        $coef-x = $coef-y × cos($mid-lat);
      }
      else {
        $height = ($height × $coef-x / ($coef-y × cos($mid-lat)) + 2 × $margin).Int;
        $coef-y = $coef-x / cos($mid-lat);
      }
    }
    when 'max' {
      if $coef-x < $coef-y × cos($mid-lat) {
        $width  = ($width × $coef-y × cos($mid-lat) / $coef-x + 2 × $margin).Int;
        $coef-x = $coef-y × cos($mid-lat);
      }
      else {
        $height = ($height × $coef-x / ($coef-y × cos($mid-lat)) + 2 × $margin).Int;
        $coef-y = $coef-x / cos($mid-lat);
      }
    }
  }

  sub conv-x(Num $long) { return ($margin + ($long - $long-min) × $coef-x).Int };
  sub conv-y(Num $lat ) { return ($margin + ($lat-max   - $lat) × $coef-y).Int };

  if @areas.elems == 1 {
    $width  = 2 × $margin;
    $height = $width;
  }

  my $image = GD::Image.new($width + $dim-scale, $height + $dim-scale);
  my $white = $image.colorAllocate(255, 255, 255);
  my $black = $image.colorAllocate(  0,   0,   0);
  my %rgb   = colors();
  my %color = Black => $black; # $black is already allocated, so it must be entered into %color without being allocated twice
  for %rgb.keys -> $color {
    if $color ne 'Black' {
      %color{$color} = $image.colorAllocate(|%rgb{$color});
    }
  }

  if $with_scale && @areas.elems > 1 {
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
    my $length-of-one-degree = 111 × cos(π / 180 × ($lat-max + $lat-min) / 2);
    loop ($scale-distance = 10_000; $scale-distance > 0.001; $scale-distance /= 10) {
      $left-scale =  conv-x($long-max - $scale-distance / $length-of-one-degree);
      last if conv-x($long-max) - $left-scale < $lg-max;
    }
    $scale-label = "$scale-distance km";
    $x-scale     = $left-scale - 6 × $scale-label.chars;
    $image.line($left-scale, $height + $dim-scale / 2, conv-x($long-max), $height + $dim-scale / 2, $black);
    $image.string(gdSmallFont, $x-scale, $height, $scale-label, $black);
  }

  my Str $imagemap = '';

  for @borders -> $border {
    my Int $xf = conv-x($border<long_f>.Num);
    my Int $yf = conv-y($border<lat_f >.Num);
    my Int $xt = conv-x($border<long_t>.Num);
    my Int $yt = conv-y($border<lat_t >.Num);

    # Is there a middle point?
    my Int $xm = 0;
    my Int $ym = 0;
    if $border<cross_idl> == 1 {
      # there is a middle point, but it is displayed as an end point because the line crosses the IDL
      $xt = conv-x($border<long_m>.Num);
      $yt = conv-y($border<lat_m >.Num);
    }
    elsif $border<long_m> != 0 or $border<lat_m> != 0 {
      # there is a middle point and it has nothing to do with the IDL
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

    $imagemap ~= draw-border($image, $xf, $yf, $xm, $ym, $xt, $yt, %color{$border<color>}, $border<color>, $thickness, $border<fruitless>, $border<name> // '', $black);
  }
  for @areas -> $area {
    my Int $x = conv-x($area<long>.Num);
    my Int $y = conv-y($area<lat >.Num);
    #say join ' ', $area<code>, $area<long>, $area<lat>, $x, $y;
    if %must-display-main{$area<code>} // True {
      $imagemap ~= draw-area($image, $x, $y, $area<code>, $white, $black, %color{$area<color>}, $area<url>, $area<name>, False);
    }
    if %long-of-relay{$area<code>} {
      $x = conv-x(%long-of-relay{$area<code>});
      $y = conv-y( %lat-of-relay{$area<code>});
      $imagemap ~= draw-area($image, $x, $y, $area<code>, $white, $black, %color{$area<color>}, $area<url>, $area<name>, True);
    }
  }

  return $image.png(), $imagemap;
}

sub draw-border($img, Int $x-from
                    , Int $y-from
                    , Int $x-mid is copy
                    , Int $y-mid is copy
                    , Int $x-to
                    , Int $y-to
                    ,     $color
                    , Str $color-name
                    , Int $thickness
                    , Int $fruitless
                    , Str $name
                    ,     $ink) {
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
    my ($dx, $dy) = ( 2.5 × $name.chars,  5);
    $img.string(gdSmallFont, $x-mid - $dx, $y-mid - $dy, $name, $ink);
    $title-text = "<area coords='{$x-mid - $dx}"
                             ~ ",{$y-mid - $dy}"
                             ~ ",{$x-mid + $dx}"
                             ~ ",{$y-mid + $dy}"
                             ~ "' title='$name'>\n";

  }
  return $title-text;
}

sub draw-area($img, Int $x, Int $y
                  , Str $txt
                  ,     $backg  # background colour
                  ,     $ink    # text colour
                  ,     $color  # line colour
                  , Str $url
                  , Str $name is copy
                  , Bool $shadow) {
  my ($dx, $dy) = ( 2.5 × $txt.chars,  5);
  my Int $radius   =  5 × $txt.chars;
  if $radius < 10 {
    # If $radius is 5, it reflects the half-width of the one-char string, but not its half-height which is a bit more.
    $radius = 10;
  }
  my Int $diameter =  2 × $radius;
  $img.setThickness(3);
  if $shadow {
    $img.filledRectangle($x - $radius, $y - $radius, $x + $radius, $y + $radius, $backg);
    $img.rectangle(      $x - $radius, $y - $radius, $x + $radius, $y + $radius, $color);
  }
  else {
    $img.filledEllipse($x, $y, $diameter, $diameter, $backg);
    $img.ellipse(      $x, $y, $diameter, $diameter, $color);
  }
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

sub adjust-from-query(Str $query-string) {
  my Str $p = param-from-query($query-string, 'adj');
  if $p ne 'h' | 'w' | 'min' | 'max' {
    $p = 'nothing';
  }
  return $p;
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

Copyright 2022, 2023, 2024 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
