package App;

use strict;
use warnings;
use v5.22;

use Mojo::Base 'Mojolicious';

use Mojolicious::Plugin::TtRenderer;
use App::Controller::Paste;
use App::Controller::Eval;
use App::Controller::Apiv1;
use App::Controller::Apiv2;
use App::Model::Paste;
use App::Model::Eval;
use App::Model::Perlbot;
use App::Model::Languages;

sub startup {
  my $self = shift;

  # TODO get this to load the proper stuff from the config into the app
  my $cfg_plg = $self->plugin('TomlConfig');
  #  $self->config($cfg->{mojolicious});

  $self->plugin('RemoteAddr');


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

  $self->helper(paste   => sub {state $paste   = App::Model::Paste->new});
  $self->helper(eval    => sub {state $eval    = App::Model::Eval->new});
  $self->helper(perlbot => sub {state $perlbot = App::Model::Perlbot->new});
  $self->helper(languages => sub {state $languages = App::Model::Languages->new});

  $self->setup_routes();
}

sub setup_routes {
  my $self = shift;

  # TODO some kind of app config for this
  App::Controller::Paste->routes($self->routes);
  App::Controller::Eval->routes($self->routes);
  App::Controller::Apiv1->routes($self->routes);
  App::Controller::Apiv2->routes($self->routes);
}

1;
