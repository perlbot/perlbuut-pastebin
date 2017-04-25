package App::Controller::Paste;

use strict;
use warnings;

use App::Config;
use Mojo::Base 'Mojolicious::Controller';

sub routes {
  my ($class, $r) = @_;

  my $route = sub {
    my ($method, $route, $action) = @_;
    $r->$method($route)->to(controller => 'paste', action => $action);
  };


  $route->(get => '/pastebin' => 'to_root');
  $route->(get => '/paste' => 'to_root');
  $route->(get => '/edit' => 'to_root');

  $route->(get => '/' => 'root');
  $route->(post => '/paste' => 'post_paste');
  $route->(get => '/edit/:pasteid' => 'edit_paste');
  $route->(get => '/raw/:pasteid' => 'raw_paste');
  $route->(get => '/pastebin/:pasteid' => 'get_paste');
  $route->(get => '/robots.txt' => 'robots'); # TODO move to static file
}

sub to_root {
  my $self = shift;

  $self->redirect_to('/');
}

sub root {
    my $c    = shift;
    $c->stash({pastedata => q{}, channels => $cfg->{announce}{channels}, page_tmpl => 'editor.html'});
    $c->render("page");
};

sub post_paste {
    my $c = shift;

    my @args = map {($c->param($_))} qw/paste name desc chan expire language/;

    my $id = $c->paste->insert_pastebin(@args);
    my ($code, $who, $desc, $channel) = @args;

    # TODO select which one based on config
# TODO make this use the config, or http params for the url

# FIXME do this properly
#    if (my $type = App::Spamfilter::is_spam($c, $who, $desc, $code)) {
#        warn "I thought this was spam! $type";
      if ($channel) { # TODO config for allowing announcements
        $c->perlbot->announce($channel, $who, substr($desc, 0, 40), "https://perlbot.pl/pastebin/$id");
      }

    $c->redirect_to('/pastebin/'.$id);
    #$c->render(text => "post accepted! $id");
};

sub edit_paste {
    my $c = shift;

    my $pasteid = $c->param('pasteid');
    
    my $row = $c->paste->get_paste($pasteid);

    if ($row->{when}) {
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

    if ($row) {
        $c->stash($row);
        $c->stash({page_tmpl => 'viewer.html'});
        $c->stash({eval => $c->eval->get_eval($pasteid, $row->{paste}, $row->{language})});
        $c->stash({paste_id => $pasteid});

        $c->render('page');
    } else {
        return $c->reply->not_found;
    }

};


sub robots  {
    my ($c) = @_;

    $c->render(text => qq{User-agent: *
Disallow: /}, format => 'txt');
};


1;
