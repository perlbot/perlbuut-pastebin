package App::Controller::Apiv1;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Controller';

sub routes {
  my ($class, $_r) = @_;

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
    
    my $row = get_paste($pasteid); 

    if ($row) {
        my $data = {
          paste => $row->{paste},
          when => $row->{when},
          username => $row->{who},
          description => $row->{desc},
          language => $row->{language},
          output => get_eval($pasteid, $row->{paste})
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

    my $id = insert_pastebin(@args);
    my ($code, $who, $desc, $channel) = @args;

    # TODO select which one based on config
    # TODO make this use the config, or http params for the url


#    if (my $type = App::Spamfilter::is_spam($c, $who, $desc, $code)) {
#        warn "I thought this was spam! $type";
#    } else {
#        if ($channel) { # TODO config for allowing announcements
#          IRC::Perlbot::announce($channel, $who, substr($desc, 0, 40), "https://perlbot.pl/pastebin/$id");
##        }
#    }

    $c->render(json => {
      url => "https://perlbot.pl/pastebin/$id", # TODO base url in config
      id => $id,
    });
    #$c->render(text => "post accepted! $id");
};

## TODO make this come from a perlbot model
sub api_get_languages {
  my $c=shift;

  $c->render(json => {languages => [
    {name => "perl", description => "Perl (blead/git)"},
    {name => "perl4", description => "Perl 4.0.36"},
    {name => "perl5.5", description => "Perl 5.5"},
    {name => "perl5.6", description => "Perl 5.6"},
    {name => "perl5.8", description => "Perl 5.8"},
    {name => "perl5.10", description => "Perl 5.10"},
    {name => "perl5.12", description => "Perl 5.12"},
    {name => "perl5.14", description => "Perl 5.14"},
    {name => "perl5.16", description => "Perl 5.16"},
    {name => "perl5.18", description => "Perl 5.18"},
    {name => "perl5.20", description => "Perl 5.20"},
    {name => "perl5.22", description => "Perl 5.22"},
    {name => "perl5.24", description => "Perl 5.24"},
    {name => "text", description => "Plain text"},
  ]});
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
