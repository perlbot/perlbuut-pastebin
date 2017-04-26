package App::Model::Languages;

use strict;
use warnings;

use Mojo::Base '-base';

my @langs = (
    {name => "perl",      mode => "perl", description => "Perl (blead/git)"},
    {name => "deparse",   mode => "perl", description => "Deparsed Perl"},
    {name => "ruby",      mode => "ruby", description => "Ruby (2.1)"},
    {name => "text",      mode => "text", description => "Plain text"},
    {name => "perl5.24",  mode => "perl", description => "Perl 5.24"},
    {name => "perl5.22",  mode => "perl", description => "Perl 5.22"},
    {name => "perl5.20",  mode => "perl", description => "Perl 5.20"},
    {name => "perl5.18",  mode => "perl", description => "Perl 5.18"},
    {name => "perl5.16",  mode => "perl", description => "Perl 5.16"},
    {name => "perl5.14",  mode => "perl", description => "Perl 5.14"},
    {name => "perl5.12",  mode => "perl", description => "Perl 5.12"},
    {name => "perl5.10",  mode => "perl", description => "Perl 5.10"},
    {name => "perl5.8",   mode => "perl", description => "Perl 5.8"},
    {name => "perl5.6",   mode => "perl", description => "Perl 5.6"},
    {name => "perl5.5",   mode => "perl", description => "Perl 5.5"},
    {name => "perl4",     mode => "perl", description => "Perl 4.0.36"},
);

my %langs = (
  map {$_->{name} => $_} @langs,
);

sub language_to_acemode {
  my ($self, $lang) = @_;

  return $langs{$lang}{mode} // "text";
}

sub get_language_hash {
  return \%langs;
}

sub get_languages {
  return \@langs
}

1;
