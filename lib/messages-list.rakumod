# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#     Génération de la liste des messages pour une carte ou pour une région
#     Generating the messages list for a map or a region
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

unit package messages-list;

use Template::Anti :one-off;
use MIME::Base64;

my @errcode = <INIT MAC1 MAC2 MAC3 MAC4 MAC5 MAC6 MAC7 MAC8
                    REG1 REG2 REG3 REG4 REG5 REG6 REG7 REG8 REG9 REGA
                    FUL1 FUL2 FUL3 FUL4 FUL5
                    FLA1 FLA2
                    ISO1 ISO2 ISO3
                    STA1 STA2
              >;

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

=begin POD

=encoding utf8

=head1 NAME

message-list.rakumod -- utility module to build an HTML list of messages

=head1 DESCRIPTION

This module  builds the  HTML list  of messages  for a  map or  just a
region is  this map. The  returned value  is just a  string containing
several  C<< <li>  ... </li>  >> lines.  This module  is used  by most
modules called by C<website.raku>.

=head1 COPYRIGHT and LICENSE

Copyright 2022, 2023, 2024 Jean Forget, all rights reserved

This program  is published under  the same conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=end POD
