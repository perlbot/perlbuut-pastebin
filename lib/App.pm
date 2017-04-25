package App;

use strict;
use warnings;
use v5.22;

use Mojo::Base 'Mojolicious';

use Mojolicious::Plugin::TtRenderer;
use App::Config;
use App::Controller::Paste;

sub startup {
  my $self = shift;

  $self->plugin('tt_renderer' => {
    template_options => {
      PRE_CHOMP => 1,
      POST_CHOMP => 1,
      TRIM => 1,
    },
  });

  $self->renderer->default_handler( 'tt' );

  if ($cfg->{features}{blogspam}) {
      $self->plugin('BlogSpam' => ($cfg->{blogspam}->%*));
  }

  $self->routes();
}

sub routes {
  my $self = shift;

  App::Controller::Paste->routes($self->routes);
  App::Controller::Eval->routes($self->routes);
  App::Controller::API::v1->routes($self->routes);
}

1;
