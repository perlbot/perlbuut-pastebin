package App::Controller::Paste;

use strict;
use warnings;

use App::Config;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::Promise;

sub routes {
  my ($class, $r) = @_;

  my $route = sub {
    my ($method, $route, $action) = @_;
    $r->$method($route)->to(controller => 'paste', action => $action);
  };


  $route->(get => '/pastebin' => 'to_root');
  $route->(get => '/paste' => 'to_root');
  $route->(get => '/p' => 'to_root');
  $route->(get => '/edit' => 'to_root');

  $route->(get => '/' => 'root');
  $route->(get => '/headers' => 'headers');
  $route->(get => '/edit/:pasteid' => 'edit_paste');
  $route->(get => '/raw/:pasteid' => 'raw_paste');
  $route->(get => '/pastebin/:pasteid' => 'get_paste');
  $route->(get => '/p/:pasteid' => 'get_paste');
  $route->(get => '/robots.txt' => 'robots'); # TODO move to static file
}

sub to_root {
  my $self = shift;

  $self->redirect_to('/');
}

sub root {
    my $c    = shift;
    $c->stash({languages => $c->languages->get_languages});
    $c->stash({pastedata => q{}, channels => $cfg->{announce}{channels}, page_tmpl => 'editor.html'});
    $c->render("page");
};

sub edit_paste {
    my $c = shift;

    my $pasteid = $c->param('pasteid');
    
    my $row = $c->paste->get_paste($pasteid);

    if ($row->{when}) {
        $c->stash({languages => $c->languages->get_languages});
        $c->stash({pastedata => $row->{paste}, channels =>$cfg->{announce}{channels}});
        $c->stash({page_tmpl => 'editor.html'});

        $c->render(template => 'page');
    } else {
        return $c->reply->not_found;
    }
};

sub raw_paste {
    my $c = shift;
    my $pasteid = $c->param('pasteid');
    
    my $row = $c->paste->get_paste($pasteid);


    if ($row) {
        $c->render(text => $row->{paste}, format => "txt");
    } else {
        return $c->reply->not_found;
    }

};
sub get_paste {
    my $c = shift;
    my $pasteid = $c->param('pasteid');
    
    my $row = $c->paste->get_paste($pasteid); 

    use Data::Dumper;
    print Dumper($row);

    if ($row) {
        my $promise = Mojo::Promise->new(sub {
            my $resolve = shift;

            $c->eval->get_eval($pasteid, $row->{paste}, [$row->{language}], 0, $resolve);
        })->then(sub {
            my ($evalres) = @_;

            my ($status, $evalout) = $evalres->@{qw/status output/};
            $c->stash($row);
            $c->stash({language => $c->languages->get_language_hash->{$row->{language}}});
            $c->stash({all_langs => $c->languages->get_language_hash});
            $c->stash({page_tmpl => 'viewer.html'});
            $c->stash({paste_id => $pasteid});
            $c->stash({eval => $evalout});
            $c->stash({eval_status => $status});
            $c->stash({perl_sort_versions => \&App::Model::Languages::perl_sort_versions});

            $c->render('page');
        });

        return $promise
    } else {
        return $c->reply->not_found;
    }

};


sub robots  {
    my ($c) = @_;

    $c->render(text => qq{User-agent: *
Disallow: /}, format => 'txt');
};

sub headers {
  my ($c) = @_;

  use Data::Dumper;
  $c->render(text => Dumper($c->req));
}

1;
