package App::Controller::Apiv1;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

sub routes {
  my ($class, $r) = @_;

  my $route = sub {
    my ($method, $route, $action) = @_;
    $r->$method($route)->to(controller => 'apiv1', action => $action);
  };

  # TODO make this use an automatic base for the version on the endpoints

  $route->(get => '/api/v1/paste/:pasteid' => 'api_get_paste');
  $route->(post => '/api/v1/paste' => 'api_post_paste');
  $route->(get => '/api/v1/languages' => 'api_get_languages');
  $route->(get => '/api/v1/channels' => 'api_get_channels');
}

sub api_get_paste {
    my $c = shift;
    my $pasteid = $c->param('pasteid');
    
    my $row = $c->paste->get_paste($pasteid); 

    if ($row) {
        my $data = {
          paste => $row->{paste},
          when => $row->{when},
          username => $row->{who},
          description => $row->{desc},
          language => $row->{language},
          output => $c->eval->get_eval($pasteid, $row->{paste}, $row->{language})
        };

        $c->render(json => $data);
    } else {
# 404
        return $c->reply->not_found;
    }
};

sub api_post_paste {
    my $c = shift;

    # TODO rate limiting

    my @args = map {($c->param($_))} qw/paste username description channel expire language/;

    my $id = $c->paste->insert_pastebin(@args, $c->tx->remote_address);
    my ($code, $who, $desc, $channel) = @args;

    # TODO select which one based on config
    # TODO make this use the config, or http params for the url

#    if (my $type = App::Spamfilter::is_spam($c, $who, $desc, $code)) {
#        warn "I thought this was spam! $type";
#    } else {
        if ($channel) { # TODO config for allowing announcements
          my $words = qr/nigger|jew|spic|tranny|trannies|fuck|shit|piss|cunt|asshole|hitler|klan|klux/i;
          unless ($code =~ $words || $who =~ $words || $desc =~ $words) {
            $c->perlbot->announce($channel, $who, substr($desc, 0, 40), $c->req->url->base()."/p/$id");
          }
        }
#    }

    $c->render(json => {
      url => $c->req->url->base()."/p/$id", # TODO base url in config
      id => $id,
    });

    if ($c->param('redirect')) {
      $c->redirect_to("/p/$id");
    }
};

## TODO make this come from a perlbot model
sub api_get_languages {
  my $c=shift;

  my $lang_ar = $c->languages->get_languages();

  $c->render(json => {languages => $lang_ar});
};

sub api_get_channels {
  my $c=shift;

  $c->render(json => {channels => [
    {name => "localhost:perlbot:#perl", description => "Freenode #perl"},
    {name => "localhost:perlbot:#perlbot", description => "Freenode #perlbot"},
    {name => "localhost:perlbot:#perlcafe", description => "Freenode #perlcafe"},
    {name => "localhost:perlbot:#buutbot", description => "Freenode #buubot"},
    {name => "localhost:perlbot:##botparadise", description => "Freenode ##botparadise"},
    {name => "localhost:perlbot-magnet:#perl", description => "irc.perl.net #perl"},
  ]});
};

1;
