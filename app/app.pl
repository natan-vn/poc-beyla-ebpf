#!/usr/bin/env perl
use Mojolicious::Lite;

# Endpoint simples
get '/' => sub {
  my $c = shift;
  $c->render(text => 'Hello, eBPF + Beyla + Perl!');
};

# Endpoint que simula consulta
get '/products' => sub {
  my $c = shift;
  $c->render(json => { products => [ "book", "pen", "laptop" ] });
};

app->start('daemon', '-l', 'http://*:1337');
