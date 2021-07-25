package App::Model::Paste;

use strict;
use warnings;

use DBI;
use App::Config;
use Mojo::Base '-base';
use DateTime;
use Mojo::Pg;
use Regexp::Assemble;

# TODO config for dbname
# has 'dbh' => sub {DBI->connect("dbi:SQLite:dbname=pastes.db", "", "", {RaiseError => 1, sqlite_unicode => 1})};
my $cfg = App::Config::get_config('database');

has 'pg' => sub {
  Mojo::Pg->new($cfg->{dsc});
};

has 'asndbh' => sub {DBI->connect("dbi:SQLite:dbname=asn.db", "", "", {RaiseError => 1, sqlite_unicode => 1})};

sub get_word_list {
  my $self = shift;
  my ($id) = @_;

  my $word_counts = $self->pg->db->query("
  WITH vector_decomp AS (
    SELECT unnest(full_document_tsvector) AS vectors FROM posts WHERE id = ?
	)
  SELECT (vectors).lexeme as word, array_length((vectors).weights, 1) as word_count FROM vector_decomp
  ", $id)->hashes;

  return $word_counts->each;
}

sub insert_pastebin {
  my $self = shift;
  my ($paste, $who, $what, $where, $expire, $lang, $ip) = @_;
 
  $expire = undef if !$expire; # make sure it's null if it's empty

  my $id = $self->pg->db->insert('posts', 
    {
      paste => $paste, 
      who => $who, 
      where => $where, 
      when => time(), 
      expiration => $expire, 
      language => $lang, 
      ip => $ip
    }, {returning => 'id'})->hash->{id};


  # TODO this needs to retry when it fails.
  my @chars = ('a'..'z', 1..9);
  my $slug = join '', map {$chars[rand() *@chars]} 1..6;

  $self->pg->db->insert(
    'slugs',
    {
      post_id => $id,
      slug => $slug
    }
  );

  return ($slug, $id);
}

sub get_paste {
  my ($self, $pasteid) = @_;

  my $row = $self->pg->db->query(q{
    SELECT p.* 
      FROM posts p 
      LEFT JOIN slugs s ON p.id = s.post_id 
      WHERE s.slug = ?
      ORDER BY s.slug DESC 
      LIMIT 1
      }, $pasteid)->hash;

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

  my $data = $self->pg->db->select(
      'banned_words', 
      ['word'], 
      {-not_bool => 'deleted'})
    ->hashes
    ->map(sub { quotemeta $_->{word} });

  my $ra = Regexp::Assemble->new();
  $ra->add(@$data);
  my $re = $ra->re;

  return $re;
}

sub get_asn_for_ip {
  my ($self, $ip) = @_;

  my $data = $self->pg->db->select(
      'asn', 
      ['asn'], 
      {start => {'<=' => $ip},
       end => {'>=' => $ip}})
    ->hashes
    ->map(sub { $_->{asn} });

  return $data->[0];
}

sub is_banned_ip {
  my ($self, $_ip) = @_;
  return 0 if ($_ip =~ /:/); # ignore ipv6 stuff for now
  my $ip = sprintf("%03d.%03d.%03d.%03d", split(/\./, $_ip));
  
  my $asn = $self->get_asn_for_ip($ip);
  
  my $row_ar = $self->pg->db->query(
    q{
    SELECT 1
    FROM banned_ips i 
    LEFT JOIN banned_asns a ON 1=1 
    WHERE (i.ip = ? AND NOT i.deleted) OR (a.asn = ? AND NOT a.deleted)
    }, 
    $ip, $asn)->hashes;

  return 0+@$row_ar;
}

1;
