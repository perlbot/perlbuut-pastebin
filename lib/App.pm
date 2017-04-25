package App;

use strict;
use warnings;
use v5.22;

use Mojo::Base 'Mojolicious';

use Mojolicious::Plugin::TtRenderer;
use App::Config;
use App::Controller::Paste;
use App::Controller::Eval;
use App::Controller::Apiv1;

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

  $self->setup_routes();
}

sub setup_routes {
  my $self = shift;

  App::Controller::Paste->routes($self->routes);
  App::Controller::Eval->routes($self->routes);
  App::Controller::Apiv1->routes($self->routes);
}

1;
