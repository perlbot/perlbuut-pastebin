package App::Controller::Apiv1;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::Promise;

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
      my $promise = Mojo::Promise->new(sub {
        my ($resolve, $reject) = @_;
          $c->eval->get_eval($pasteid, $row->{paste}, [$row->{language}], 0, $resolve)
        })->then(sub {
          my ($evalres) = @_;

          my ($status, $output_hr) = $evalres->@{qw/status output/};

          my ($output_lang) = keys %$output_hr; # grab a random output value, should be the first one since multilang support isn't working yet
          my ($output) = $output_hr->{$output_lang};
          my $data = {
            paste => $row->{paste},
            when => $row->{when},
            username => $row->{who},
            description => $row->{desc},
            language => $output_lang,
            output => $output,
            status => $status,
            warning => "If this was multi-language paste, you just got a random language",
          };

          $c->render(json => $data);
        });
        return $promise;
    } else {
# 404
        return $c->reply->not_found;
    }
};

sub api_post_paste {
    my $c = shift;

    # TODO rate limiting

    my @args = map {($c->param($_))} qw/paste username description channel expire language/;

    my ($slug, $id) = $c->paste->insert_pastebin(@args, $c->remote_addr);
    my ($code, $who, $desc, $channel) = @args;

    # TODO select which one based on config
    # TODO make this use the config, or http params for the url

#    if (my $type = App::Spamfilter::is_spam($c, $who, $desc, $code)) {
#        warn "I thought this was spam! $type";
#    } else {
        if ($channel) { # TODO config for allowing announcements
          my $words = $c->paste->banned_word_list_re;
          my $url = $c->req->url->base()."/p/$slug";
          $url =~ s|http:|https:|;
          unless ($code =~ $words || $who =~ $words || $desc =~ $words || $c->paste->is_banned_ip($c->remote_addr)) {
            $c->perlbot->announce($channel, $who, substr($desc, 0, 40), $url);
          } else {
            printf "Not doing announcement, [%s] [%s] [%s] [%s]\n", ($code =~ $words), ($who =~ $words), ($desc =~ $words), ($c->paste->is_banned_ip($c->remote_addr));
          }
        }
#    }

    $c->render(json => {
      url => $c->req->url->base()."/p/$slug", # TODO base url in config
      id => $slug,
    });

    if ($c->param('redirect')) {
      $c->redirect_to("/p/$slug");
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
