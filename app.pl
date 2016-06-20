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
use TOML;

plugin 'tt_renderer' => {
  template_options => {
    PRE_CHOMP => 1,
    POST_CHOMP => 1,
    TRIM => 1,
  },
};

app->renderer->default_handler( 'tt' );

my $cfg = do {
    my $toml = do {open(my $fh, "<", "$Bin/app.cfg"); local $/; <$fh>};
# With error checking
    my ($data, $err) = from_toml($toml);
    unless ($data) {
            die "Error parsing toml: $err";
    }
    $data;
};

my $memd;

if ($cfg->{features}{memcached}) {
    my $namespace = delete $cfg->{memcached}{namespace};
    $namespace .= "_".time() if (delete $cfg->{memcached}{unique_namespace});

    # Only load these if we're using them
    require Cache::Memcached::Fast;
    require IO::Compress::Gzip;
    require IO::Uncompress::Gunzip;
    $memd = Cache::Memcached::Fast->new({
        namespace => $namespace // 'pastebin',
        connect_timeout => 0.2,
        io_timeout => 0.5,
        close_on_error => 1,
        compress_threshold => 1_000,
        compress_ratio => 0.9,
        compress_methods => [ \&IO::Compress::Gzip::gzip,
                              \&IO::Uncompress::Gunzip::gunzip ],
        max_failures => 3,
        failure_timeout => 2,
        ketama_points => 150,
        nowait => 1,
        hash_namespace => 1,
        serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
        utf8 => 1,
        max_size => 512 * 1024,
        $cfg->{memcached}->%*, # let the config overwrite anything set here if they want
    });
};

my $dbh = DBI->connect("dbi:SQLite:dbname=pastes.db", "", "", {RaiseError => 1});
$dbh->{sqlite_unicode} = 1;
# hardcode some channels first

sub insert_pastebin {
    my ($paste, $who, $what, $where) = @_;
    
    $dbh->do("INSERT INTO posts (paste, who, 'where', what, 'when') VALUES (?, ?, ?, ?, ?)", {}, $paste, $who, $where, $what, time());
    my $id = $dbh->last_insert_id('', '', 'posts', 'id');

    return $id;
}

sub get_eval {
    my ($paste_id, $code) = @_;
   
    if ($cfg->{features}{memcached} && (my $cached = $memd->get($paste_id))) {
        return $cached;
    } else {
        my $filter = POE::Filter::Reference->new();
        my $socket = IO::Socket::INET->new(  PeerAddr => 'localhost', PeerPort => '14400' )
            or die "error: cannot connect to eval server";

        my $refs = $filter->put( [ { code => "perl $code" } ] );

        print $socket $refs->[0]; 
        my $output = do {local $/; <$socket>};
        close $socket;
        my $result = $filter->get( [ $output ] );
        my $str = eval {decode("utf8", $result->[0]->[0])} // $result->[0]->[0];
        $str = eval {decode("utf8", $str)} // $str; # I don't know why i need to decode this twice.  shurg.
        $memd->set($paste_id, $str) if $cfg->{features}{memcached};

        return $str;
    }
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
    }

};

get '/eval/:pasteid' => sub {
    my ($c) = @_;
    my $pasteid = $c->param('pasteid');

    my $row = $dbh->selectrow_hashref("SELECT * FROM posts WHERE id = ? LIMIT 1", {}, $pasteid);
    my $code = $row->{paste} // '';

    my $output = get_eval($pasteid, $code);

    $c->render(json => {evalout => $output});
};

app->start;

