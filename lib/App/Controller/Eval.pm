package App::Controller::Eval;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Promise;

sub routes {
  my ($class, $r) = @_;

  my $route = sub {
    my ($method, $route, $action) = @_;
    $r->$method($route)->to(controller => 'eval', action => $action);
  };

  $route->(post => '/eval' => 'run_eval');
}

sub run_eval {
    my ($self) = @_;
    my $data = $self->req->body_params;

    $self = $self->inactivity_timeout(3600);

    my $code = $data->param('code') // '';
    my $language = $data->param('language') // 'perl';

    my $promise = Mojo::Promise->new(sub {
      my ($resolve, $reject) = @_;
        $self->eval->get_eval(undef, $code, [$language], 1, $resolve);
      });
    $promise->then(sub {
      my ($evalres) = @_;

      use Data::Dumper;
      print Dumper("wutwut", $evalres);
      my $output = $evalres->{output};

      $self->render(json => {evalout => $output});
    })
}

1;
