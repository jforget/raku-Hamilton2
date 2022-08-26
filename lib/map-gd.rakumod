# Ébauche de carte 

unit package map-gd;

use GD:from<Perl5>;
use List::Util;

our sub draw(@areas) {
  my Int $dim    = 1000;
  my $image = GD::Image.new($dim, $dim);

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

  sub conv-x(Num $long) { return $margin + ($long - $long-min) / ($long-max - $long-min) × ($dim - 2 × $margin) };
  sub conv-y(Num $lat ) { return $margin + ($lat-max   - $lat) / ($lat-max  -  $lat-min) × ($dim - 2 × $margin) };

  for @areas -> $area {
    my Num $x = conv-x($area<long>);
    my Num $y = conv-y($area<lat>);
    #say join ' ', $area<code>, $area<long>, $area<lat>, $x, $y;
    draw-area($image, $x.Int, $y.Int, $area<code>, $black, %color{$area<color>});
  }

  return $image.png();
}

sub draw-area($img, $x, $y, $txt, $black, $color) {
  my ($dx, $dy) = ( 2.5 × $txt.chars,  5);
  my $r = 10 × $txt.chars;
  $img.setThickness(3);
  $img.ellipse($x, $y, $r, $r, $color);
  $img.setThickness(1);
  $img.string(gdSmallFont, $x - $dx, $y - $dy, $txt, $black);
}
