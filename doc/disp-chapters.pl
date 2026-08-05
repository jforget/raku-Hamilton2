#!/usr/bin/perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Afficher les chapitres d'un fichier HTML (encadré par Hn)
# Display the chapters from an HTML file
#

use v5.10;
use strict;
use warnings;
use HTML::TokeParser;

for (@ARGV) {
  disp_chap($_);
}

sub disp_chap {
  my ($fic) = @_;
  my $p = HTML::TokeParser->new($fic)
    or die "Opening $fic : $!";
  my $dsp = 0;
  my @title;
  while (my $token = $p->get_token) {
    if ($dsp && $token->[0] eq 'T') {
      my $txt = $token->[1];
      $txt =~ s/\n/ /g;
      push @title, $txt;
    }
    if ($token->[0] eq 'E' && $token->[1] =~ /^h\d/i) {
      $dsp = 0;
      say @title;
    }
    if ($token->[0] eq 'S' && $token->[1] =~ /^h\d/i) {
      $dsp = 1;
      @title = ($token->[1], " ");
    }
  }
}

__END__

=encoding utf8

=head1 NAME

disp-chapter.pl -- display chapters from an HTML file

=head1 SYNOPSIS

  /usr/bin/grip --export --no-inline Hamilton.en.md
  perl disp-chapter.pl Hamilton.en.html

=head1 DESCRIPTION

This program reads an HTML file  and extracts all the text embedded in
C<< <Hn> >> tags.  For each found tag, the program  prints it with the
relevant text.

=head1 OPTIONS

None

=head1 PARAMETERS

There  is  a single  parameter,  the  pathname of the HTML file.

You  can parse  several  HTML  files by  giving  several command  line
parameters, separated with whitespace.

=head1 KNOWN BUGS

The program  should have coded iun  Raku. The problem is  that, at the
moment, there is  no Raku module for  parsing HTML with a  SAX API. So
here it is, in Perl, with C<HTML::TokeParser>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2026 Jean Forget, all rights reserved

This programme  is published  under the same  conditions as  Raku: the
Artistic License version 2.0.

The text of  the licenses is available  in the F<LICENSE-ARTISTIC-2.0>
file in this repository, or you can read them at:

  L<https://raw.githubusercontent.com/Raku/doc/master/LICENSE>

=cut
