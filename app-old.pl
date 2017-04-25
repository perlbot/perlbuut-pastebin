#!/usr/bin/env perl

use strict;
use warnings;
use v5.22;
no warnings "experimental::postderef";
use feature "postderef", "postderef_qq";

use FindBin qw($Bin);
use lib "$Bin/lib";
use Data::Dumper;
use DBI;
use Encode qw/decode/;

use Mojolicious::Lite;
use Mojolicious::Plugin::TtRenderer;
use POE::Filter::Reference;
use App::Config;
use App::Memcached;
use Eval::Perlbot;
use IRC::Perlbot;
use DateTime;
use App::Spamfilter;

plugin 'tt_renderer' => {
  template_options => {
    PRE_CHOMP => 1,
    POST_CHOMP => 1,
    TRIM => 1,
  },
};

app->renderer->default_handler( 'tt' );

if ($cfg->{features}{blogspam}) {
    plugin 'BlogSpam' => ($cfg->{blogspam}->%*);
}

my $dbh = DBI->connect("dbi:SQLite:dbname=pastes.db", "", "", {RaiseError => 1});
$dbh->{sqlite_unicode} = 1;
# hardcode some channels first

sub insert_pastebin {
    my ($paste, $who, $what, $where, $expire, $lang) = @_;
   
    $expire = undef if !$expire; # make sure it's null if it's empty

    $dbh->do("INSERT INTO posts (paste, who, 'where', what, 'when', 'expiration', 'language') VALUES (?, ?, ?, ?, ?, ?, ?)", {}, $paste, $who, $where, $what, time(), $expire, $lang);
    my $id = $dbh->last_insert_id('', '', 'posts', 'id');

    # TODO this needs to retry when it fails.
    my @chars = ('a'..'z', 1..9);
    my $slug = join '', map {$chars[rand() *@chars]} 1..6;
    $dbh->do("INSERT INTO slugs (post_id, slug) VAlUES (?, ?)", {}, $id, $slug);

    return $slug;
}

get '/' => sub {
    my $c    = shift;
    $c->stash({pastedata => q{}, channels => $cfg->{announce}{channels}, page_tmpl => 'editor.html'});
    $c->render("page");
};
get '/pastebin' => sub {$_[0]->redirect_to('/')};
get '/paste' => sub {$_[0]->redirect_to('/')};


post '/paste' => sub {
    my $c = shift;

    my @args = map {($c->param($_))} qw/paste name desc chan expire language/;

    my $id = insert_pastebin(@args);
    my ($code, $who, $desc, $channel) = @args;

    # TODO select which one based on config
# TODO make this use the config, or http params for the url

    if (my $type = App::Spamfilter::is_spam($c, $who, $desc, $code)) {
        warn "I thought this was spam! $type";
    } else {
        IRC::Perlbot::announce($c->param('chan'), $c->param('name'), substr($c->param('desc'), 0, 40), "https://perlbot.pl/pastebin/$id");
    }

    $c->redirect_to('/pastebin/'.$id);
    #$c->render(text => "post accepted! $id");
};

get '/edit/:pasteid' => sub {
    my $c = shift;
    my $pasteid = $c->param('pasteid');
    
    my $row = $dbh->selectrow_hashref("SELECT * FROM posts WHERE id = ? LIMIT 1", {}, $pasteid);

    if ($row->{when}) {
        $c->stash({pastedata => $row->{paste}, channels =>$cfg->{announce}{channels}});
        $c->stash({page_tmpl => 'editor.html'});

        $c->render('page');
    } else {
# 404
        return $c->reply->not_found;
    }
};

sub get_paste {
    my $pasteid = shift;
    my $row = $dbh->selectrow_hashref(q{
      SELECT p.* 
        FROM posts p 
        LEFT JOIN slugs s ON p.id = s.post_id 
        WHERE p.id = ? OR s.slug = ?
        ORDER BY s.slug DESC 
        LIMIT 1
      }, {}, $pasteid, $pasteid);

    my $when = delete $row->{when};

    if ($when) {
      my $whendt = DateTime->from_epoch(epoch => $when);

      if (!$row->{expiration} || $whendt->clone()->add(hours => $row->{expiration}) >= DateTime->now()) {
        $row->{when} = $whendt->iso8601;
        return $row;
      } else {
        return undef;
      }
    } else {
      return undef;
    }
}

get '/raw/:pasteid' => sub {
    my $c = shift;
    my $pasteid = $c->param('pasteid');
    
    my $row = get_paste($pasteid);


    if ($row) {
        $c->render(text => $row->{paste}, format => "txt");
    } else {
# 404
        return $c->reply->not_found;
    }

};
get '/pastebin/:pasteid' => sub {
    my $c = shift;
    my $pasteid = $c->param('pasteid');
    
    my $row = get_paste($pasteid); 

    if ($row) {
        $c->stash($row);
        $c->stash({page_tmpl => 'viewer.html'});
        $c->stash({eval => get_eval($pasteid, $row->{paste}, $row->{lang})});
        $c->stash({paste_id => $pasteid});

        $c->render('page');
    } else {
# 404
        return $c->reply->not_found;
    }

};

post '/eval' => sub {
    my ($c) = @_;
    my $data = $c->req->body_params;

    my $code = $data->param('code') // '';

    my $output = get_eval(undef, $code);

    $c->render(json => {evalout => $output});
};

get '/robots.txt' => sub {
    my ($c) = @_;

    $c->render(text => qq{User-agent: *
Disallow: /});
};

get '/api/v1/paste/:pasteid' => sub {
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

post '/api/v1/paste' => sub {
    my $c = shift;

    # TODO rate limiting

    my @args = map {($c->param($_))} qw/paste username description channel expire language/;

    my $id = insert_pastebin(@args);
    my ($code, $who, $desc, $channel) = @args;

    # TODO select which one based on config
    # TODO make this use the config, or http params for the url

    if (my $type = App::Spamfilter::is_spam($c, $who, $desc, $code)) {
        warn "I thought this was spam! $type";
    } else {
        if ($channel) { # TODO config for allowing announcements
          IRC::Perlbot::announce($channel, $who, substr($desc, 0, 40), "https://perlbot.pl/pastebin/$id");
        }
    }

    $c->render(json => {
      url => "https://perlbot.pl/pastebin/$id", # TODO base url in config
      id => $id,
    });
    #$c->render(text => "post accepted! $id");
};

get '/api/v1/languages' => sub {
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

get '/api/v1/channels' => sub {
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

app->start;

