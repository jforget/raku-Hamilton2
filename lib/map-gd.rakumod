# Ébauche de carte 

unit package map-gd;

use GD:from<Perl5>;
use List::Util;

our sub draw(@areas) {
  my Int $dim    = 1000;
  my $image = GD::Image.new($dim, $dim);

  my $white  = $image.colorAllocate(255, 255, 255);
  my $black  = $image.colorAllocate(  0,   0,   0);

  my Num $long-min = min map { $_<long> }, @areas;
  my Num $long-max = max map { $_<long> }, @areas;
  my Num $lat-min  = min map { $_<lat>  }, @areas;
  my Num $lat-max  = max map { $_<lat>  }, @areas;
  my Int $char-max = max map { $_<code>.chars }, @areas;
  my Int $margin =  5 × $char-max;

  for @areas -> $area {
    my Num $x = $margin + ($area<long> - $long-min ) / ($long-max - $long-min) × ($dim - 2 × $margin);
    my Num $y = $margin + ($lat-max    - $area<lat>) / ($lat-max  -  $lat-min) × ($dim - 2 × $margin);
    #say join ' ', $area<code>, $area<long>, $area<lat>, $x, $y;
    sommet($image, $x.Int, $y.Int, $area<code>, $black);
  }

  return $image.png();
}

sub sommet($img, $x, $y, $txt, $black) {
  my ($dx, $dy) = ( 2.5 × $txt.chars,  5);
  my $r = 10 × $txt.chars;
  $img.setThickness(3);
  $img.ellipse($x, $y, $r, $r, $black);
  $img.setThickness(1);
  $img.string(gdSmallFont, $x - $dx, $y - $dy, $txt, $black);
}
