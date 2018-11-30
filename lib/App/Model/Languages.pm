package App::Model::Languages;

use strict;
use warnings;

use Mojo::Base '-base';

my @langs = (
    {name => "perl5.28",  mode => "perl", description => "Perl 5.28"},
    {name => "perl6",     mode => "perl", description => "Rakudo Star / Perl 6"},
    {name => "bash",      mode => "bash", description => "Bash"},
    {name => "ruby",      mode => "ruby", description => "Ruby (2.1)"},
    {name => "javascript", mode => "javascript", description => "Javascript/Node.js"},
    {name => "tcc",       mode => "c_cpp",    description => "TCC 0.9.27"},
    {name => "text",      mode => "text", description => "Plain text"},
    {name => "text",      mode => "text", description => "----------"},
    {name => "cobol",     mode => "cobol", description => "GnuCOBOL 2.2"},
    {name => "perl",      mode => "perl", description => "Perl 5 (blead/git)"},
    {name => "deparse",   mode => "perl", description => "Deparsed Perl"},
    {name => "evalall",   mode => "perl", description => "Perl (EvalAll)"},
    {name => "perl5.26",  mode => "perl", description => "Perl 5.26"},
    {name => "perl5.26t",  mode => "perl", description => "Perl 5.26 (Threaded)"},
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
    {name => "perl5.4",   mode => "perl", description => "Perl 5.004"},
    {name => "perl5.3",   mode => "perl", description => "Perl 5.003"},
    {name => "perl5.2",   mode => "perl", description => "Perl 5.002"},
    {name => "perl5.1",   mode => "perl", description => "Perl 5.001"},
    {name => "perl5.0",   mode => "perl", description => "Perl 5.000"},
    {name => "perl4",     mode => "perl", description => "Perl 4.0.36"},
    {name => "perl3",     mode => "perl", description => "Perl 3.0.1.10_44"},
    {name => "perl2",     mode => "perl", description => "Perl 2"},
    {name => "perl1",     mode => "perl", description => "Perl 1"},
    {name => "cperl",     mode => "perl", description => "CPerl 5.26"},

);

# Add a sorting rank to each language
for my $i (0..$#langs) {
  my $r = $i; 
  $r = -1 if ($langs[$i]{name} eq 'perl'); # specially handle blead as being top dog
  $langs[$i]{rank} = $r;
}

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

sub perl_sort_versions {
  return $_[0] unless ref($_[0]);
  my @in = @{shift()};
  my @ranks = map {$langs{$_}{rank}} @in;
  my @ret = sort {$langs{$a}{rank} <=> $langs{$b}{rank}} @in;
  return @ret;
}

1;
