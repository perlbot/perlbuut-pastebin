package App::Controller::Eval;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

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

    my $code = $data->param('code') // '';
    my $language = $data->param('language') // 'perl';

    my $output = $self->eval->get_eval(undef, $code, $language);

    $c->render(json => {evalout => $output});
};

1;
