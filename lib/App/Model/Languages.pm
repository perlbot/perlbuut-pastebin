package App::Model::Languages;

use strict;
use warnings;

use Mojo::Base '-base';

my %langs = (
    "perl" =>     {mode => "perl", description => "Perl (blead/git)"},
    "perl4" =>    {mode => "perl", description => "Perl 4.0.36"},
    "perl5.5" =>  {mode => "perl", description => "Perl 5.5"},
    "perl5.6" =>  {mode => "perl", description => "Perl 5.6"},
    "perl5.8" =>  {mode => "perl", description => "Perl 5.8"},
    "perl5.10" => {mode => "perl", description => "Perl 5.10"},
    "perl5.12" => {mode => "perl", description => "Perl 5.12"},
    "perl5.14" => {mode => "perl", description => "Perl 5.14"},
    "perl5.16" => {mode => "perl", description => "Perl 5.16"},
    "perl5.18" => {mode => "perl", description => "Perl 5.18"},
    "perl5.20" => {mode => "perl", description => "Perl 5.20"},
    "perl5.22" => {mode => "perl", description => "Perl 5.22"},
    "perl5.24" => {mode => "perl", description => "Perl 5.24"},
    "text" =>     {mode => "text", description => "Plain text"},
    "ruby" =>     {mode => "ruby", description => "Ruby (2.1)"},
);

sub language_to_acemode {
  my ($self, $lang) = @_;

  return $langs{$lang}{mode} // "text";
}

sub get_languages {
  return \%langs;
}

1;
