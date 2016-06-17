#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Data::Dumper;
use DBI;

use Mojolicious::Lite;
use Mojolicious::Plugin::TtRenderer;

plugin 'tt_renderer';
app->renderer->default_handler( 'tt' );
app->renderer->paths( [ './tt' ] );

my $dbh = DBI->connect("dbi:SQLite:dbname=pastes.db", "", "", {RaiseError => 1});
# hardcode some channels first
my %channels = (
    "freenode#perlbot" => "#perlbot (freenode)",
    "freenode#perl" => "#perl (freenode)",
);

get '/' => sub {
    my $c    = shift;
    $c->stash({pastedata => q{}, channels => \%channels, viewing => 0});
    $c->render(template => "editor");
};
get '/pastebin' => sub {$_[0]->redirect_to('/')};
get '/paste' => sub {$_[0]->redirect_to('/')};


post '/paste' => sub {
    my $c = shift;

    my @args = map {($c->param($_))} qw/paste user chan desc/;

    $dbh->do("INSERT INTO posts (paste, who, 'where', what, 'when') VALUES (?, ?, ?, ?, ?)", {}, @args, time());
    my $id = $dbh->last_insert_id('', '', 'posts', 'id');

    $c->redirect_to('/pastebin/'.$id);
    #$c->render(text => "post accepted! $id");
};

get '/pastebin/:pasteid' => sub {
    my $c = shift;
    my $pasteid = $c->param('pasteid');
    
    my $row = $dbh->selectrow_hashref("SELECT * FROM posts WHERE id = ? LIMIT 1", {}, $pasteid);

    print Dumper($row);

    if ($row->{when}) {
        $c->stash({pastedata => $row->{paste}, channels => \%channels, viewing => 1});
        $c->stash($row);

        $c->render(template => "editor");
    } else {
# 404
    }

};

app->start;

