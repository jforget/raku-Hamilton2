#!/usr/bin/env perl6
# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
#
#     Serveur web permettant de consulter la base Hamilton.db des chemins doublement hamiltoniens
#     Web server to display the database storing doubly-Hamitonian paths
#     Copyright (C) 2022, 2023, 2024 Jean Forget
#
#     Voir la licence dans la documentation incluse ci-dessous.
#     See the license in the embedded documentation below.
#

use v6.d;
use lib 'lib';
use Cro::HTTP::Router;
use Cro::HTTP::Server;

use access-sql;
use map-list-page;
#use map;
#use common;
#use full-path;
#use macro-path;
#use Hamilton-stat;
#use region-path;
#use region-with-full-path;
#use deriv-ico-path;
#use shortest-path-stat;

my @languages = ( 'en', 'fr' );

my $application = route {
  get -> {
    content 'text/html', 'Hello Cro!';
  }
  get -> Str $lng, 'list' {
    if $lng !~~ /^ @languages $/ {
      content 'text/html', slurp('html/unknown-language.html');
    }
    else {
      my @maps = access-sql::list-maps;
      content 'text/html', map-list-page::render($lng, @maps);
    }
  }
  get -> Str $lng, 'full-map', Str $map, :%params {
    content 'text/html', "Carte complète $map en $lng, paramètres {%params.raku}";
  }
}

my Cro::Service $service = Cro::HTTP::Server.new:
    :host<localhost>, :port<10000>, :$application;

$service.start;

react whenever signal(SIGINT) {
    $service.stop;
    exit;
}
