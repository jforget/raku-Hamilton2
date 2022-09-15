# List of messages

unit package messages-list;

use Template::Anti :one-off;
use MIME::Base64;

my @errcode = <INIT MAC1 MAC2 MAC3 MAC4 MAC5 MAC6 MAC7 REG1 REG2 REG3 REG4 REG5 REG6 REG7>;

sub fill($at, Str :$lang, :@messages) {
  my %ligne;
  for @errcode -> $errcode {
    %ligne{$errcode} = $at.at("li.$errcode");
  }

  my Str $result;
  for @messages -> $message {
    my $ligne = %ligne{$message<errcode>};

    my $dh = $message<dh>;
    $dh .= subst(/ '.' .* /, '');
    $ligne.at('span.dh'    ).content($dh);
    $ligne.at('span.region').content($message<area>);
    $ligne.at('span.nb'    ).content($message<nb  >);
    $ligne.at('span.data'  ).content($message<data>);

    $result ~= "$ligne\n";
  }
  $at.at('html').content($result);
}

our sub render(Str $lang, @messages) {
  my &filling = anti-template :source("html/messages.$lang.html".IO.slurp), &fill;
  my Str $result = filling(lang => $lang, messages => @messages);
  $result .= subst(:g, / '<' '/'? 'html>' /, '');
  return $result;
}
