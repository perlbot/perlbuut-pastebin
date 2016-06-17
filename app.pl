#!/usr/bin/env perl

use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/lib";
use Data::Dumper;
use DBI;

use Mojolicious::Lite;

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

__DATA__

@@ editor.html.ep

<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
  <script src="https://code.jquery.com/jquery-2.2.4.min.js" ></script>

  <!-- Latest compiled and minified CSS -->
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap.min.css" integrity="sha384-1q8mTJOASx8j1Au+a5WDVnPi2lkFfwwEAa8hDDdjZlpLegxhjVME1fgjWPGmkzs7" crossorigin="anonymous">
  <!-- Optional theme -->
  <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/css/bootstrap-theme.min.css" integrity="sha384-fLW2N01lMqjakBkx3l/M9EahuwpSfeNvV63J5ezn3uZzapT0u7EYsXMjQV+0En5r" crossorigin="anonymous">
  <!-- Latest compiled and minified JavaScript -->
  <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.6/js/bootstrap.min.js" integrity="sha384-0mSbJDEHialfmuBBQP6A4Qrprq5OVfW37PRR3j5ELqxss1yVqOtnepnHVP9aJ7xS" crossorigin="anonymous"></script>

  <title>Editor</title>
  <style type="text/css" media="screen">
    #editor {
      margin: auto;
      position: relative !important;
      width: 100%;
      height: 500px;
      display: none;
    }

    #paste {
      font-family: 'mono'
    }

    html, body, #content {
      width: 100%;
    }
  </style>
</head>
<body>

<form action="/paste" method="POST" id="form">
    <div id="content" class="container">
      <div class="panel">
        <div class="panel-heading">
          <div class="row">
            % if ($viewing) {
              <div class="col-md-3">
                <b>Who: </b><%= $who %>
              </div>
              <div class="col-md-3">
                <b>When: </b><%= $when %>
              </div>
              <div class="col-md-6">
                <b>What: </b><%= $what %>
              </div>
            % } else {
              <div class="col-md-3">
                <label for="name">Who: </label>
                <input size="20" name="name" placeholder="Anonymous" />
              </div>
              <div class="col-md-3">
                <label for="chan">Where: </label>
                <select name="chan" id="chan">
                    <option value="">-- IRC Channel --</option>
                % for my $i (keys %$channels) {
                    <option value="<%= $i %>"><%= $channels->{$i} %></option>
                % }
                </select>
              </div>
              <div class="col-md-6">
                <label for="desc">What: </label>
                <input size="40" name="desc" placeholder="I broke this" />
              </div>
            % }
          </div>
        </div>
      </div>
      <div class="panel-body">
        <div class="editors">
        <textarea name="paste" id="paste" cols="80" rows="25"><%= $pastedata %></textarea>
        <pre id="editor">
        </pre>
        </div>
        <div class="panel-footer">
          % unless ($viewing) {
          <input value="Submit" type="submit" id="submit" />
          % }
        </div>
      </div>
    </div>
</form>

<script src="/static/ace/ace.js" type="text/javascript" charset="utf-8"></script>
<script>
    $("#paste").hide();
    $("#editor").show();
    $("#editor").text($("#paste").text());
    var editor = ace.edit("editor");
    //editor.setTheme("ace/theme/twilight");
    editor.session.setMode("ace/mode/perl");

    % if ($viewing) {
        editor.setReadOnly(true);
    % }

    function resizeAce() {
      var h = window.innerHeight;
      if (h > 360) {
        $('#editor').css('height', (h - 175).toString() + 'px');
      }
    };
    $(window).on('resize', function () {
      resizeAce();
    });
    resizeAce();

    $("#submit").on('click', function () {
        $("#paste").text(editor.getValue()); // copy to the textarea
    });

</script>

</body>
</html>
