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

plugin 'tt_renderer' => {
  template_options => {
    PRE_CHOMP => 1,
    POST_CHOMP => 1,
    TRIM => 1,
  },
};

app->renderer->default_handler( 'tt' );

my $dbh = DBI->connect("dbi:SQLite:dbname=pastes.db", "", "", {RaiseError => 1});
$dbh->{sqlite_unicode} = 1;
# hardcode some channels first

sub insert_pastebin {
    my ($paste, $who, $what, $where) = @_;
    
    $dbh->do("INSERT INTO posts (paste, who, 'where', what, 'when') VALUES (?, ?, ?, ?, ?)", {}, $paste, $who, $where, $what, time());
    my $id = $dbh->last_insert_id('', '', 'posts', 'id');

    return $id;
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

    my @args = map {($c->param($_))} qw/paste name desc chan/;

    my $id = insert_pastebin(@args);

    # TODO select which one based on config
# TODO make this use the config, or http params for the url
    my ($channel, $who, $what, $link) = @_;
    IRC::Perlbot::announce($c->param('chan'), $c->param('name'), $c->param('desc'), "https://perlbot.pl/pastebin/$id");

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

get '/pastebin/:pasteid' => sub {
    my $c = shift;
    my $pasteid = $c->param('pasteid');
    
    my $row = $dbh->selectrow_hashref("SELECT * FROM posts WHERE id = ? LIMIT 1", {}, $pasteid);

    if ($row->{when}) {
        $c->stash($row);
        $c->stash({page_tmpl => 'viewer.html'});
        $c->stash({eval => get_eval($pasteid, $row->{paste})});
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

app->start;

