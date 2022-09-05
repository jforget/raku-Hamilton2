# Ébauche de carte 

unit package map-gd;

use GD:from<Perl5>;
use List::Util;

our sub draw(@areas, @borders) {
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
  %color<Yellow> = $image.colorAllocate(127, 127,   0);

  my Num $long-min = min map { $_<long> }, @areas;
  my Num $long-max = max map { $_<long> }, @areas;
  my Num $lat-min  = min map { $_<lat>  }, @areas;
  my Num $lat-max  = max map { $_<lat>  }, @areas;
  my Int $char-max = max map { $_<code>.chars }, @areas;
  my Int $margin   = 6 × $char-max;

  sub conv-x(Num $long) { return ($margin + ($long - $long-min) / ($long-max - $long-min) × ($dim - 2 × $margin)).Int };
  sub conv-y(Num $lat ) { return ($margin + ($lat-max   - $lat) / ($lat-max  -  $lat-min) × ($dim - 2 × $margin)).Int };

  my $scale-distance;
  my $top-scale;
  loop ($scale-distance = 10_000; $scale-distance > 1; $scale-distance /= 10) {
    $top-scale =  conv-y($lat-min + $scale-distance / 111);
    last if conv-y($lat-min) - $top-scale < $lg-max;
  }
  my $scale-label = "$scale-distance km";
  my $x-scale     = $dim + $dim-scale - 6 × $scale-label.chars;
  $image.line($dim, conv-y($lat-min), $dim, $top-scale, $black);
  $image.string(gdSmallFont, $x-scale, $top-scale - 20, $scale-label, $black);

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
    draw-border($image, $xf, $yf, $xm, $ym, $xt, $yt, %color{$border<color>});
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

sub draw-border($img, Int $x-from, Int $y-from, Int $x-mid, Int $y-mid, Int $x-to, Int $y-to, $color) {
  $img.setThickness(1);
  if $x-mid == 0 && $y-mid == 0 {
    $img.line($x-from, $y-from, $x-to , $y-to , $color);
  }
  else {
    $img.line($x-from, $y-from, $x-mid, $y-mid, $color);
    $img.line($x-mid , $y-mid , $x-to , $y-to , $color);
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
