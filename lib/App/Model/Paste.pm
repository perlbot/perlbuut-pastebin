package App::Model::Paste;

use strict;
use warnings;

use DBI;
use Mojo::Base '-base';
use DateTime;

# TODO config for dbname
has 'dbh' => sub {DBI->connect("dbi:SQLite:dbname=pastes.db", "", "", {RaiseError => 1, sqlite_unicode => 1})};

sub insert_pastebin {
  my $self = shift;
  my $dbh = $self->dbh;
  my ($paste, $who, $what, $where, $expire, $lang, $ip) = @_;
 
  $expire = undef if !$expire; # make sure it's null if it's empty

  $dbh->do("INSERT INTO posts (paste, who, 'where', what, 'when', 'expiration', 'language', 'ip') VALUES (?, ?, ?, ?, ?, ?, ?, ?)", {}, $paste, $who, $where, $what, time(), $expire, $lang, $ip);
  my $id = $dbh->last_insert_id('', '', 'posts', 'id');

  # TODO this needs to retry when it fails.
  my @chars = ('a'..'z', 1..9);
  my $slug = join '', map {$chars[rand() *@chars]} 1..6;
  $dbh->do("INSERT INTO slugs (post_id, slug) VAlUES (?, ?)", {}, $id, $slug);

  return $slug;
}

sub get_paste {
  my ($self, $pasteid) = @_;

  my $dbh = $self->dbh;
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

sub banned_word_list_re {
  my $self = shift;

  my $data = $self->dbh->selectall_arrayref("SELECT word FROM banned_words WHERE deleted <> 1");

  my $re_str = join '|', map {quotemeta $_->[0]} @$data;
  my $re = qr/($re_str)/i;

  return $re;
}

1;
