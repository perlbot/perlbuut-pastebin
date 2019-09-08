package App::Model::Languages;

use strict;
use warnings;

use Mojo::Base '-base';

my @langs = (
    {name => "perl5.30",  mode => "perl", description => "Perl 5.30"},
    {name => "perl6",     mode => "perl", description => "Rakudo Star / Perl 6"},
    {name => "bash",      mode => "bash", description => "Bash"},
    {name => "ruby",      mode => "ruby", description => "Ruby (2.1)"},
    {name => "javascript", mode => "javascript", description => "Javascript/Node.js"},
    {name => "tcc",       mode => "c_cpp",    description => "TCC 0.9.27"},
    {name => "text",      mode => "text", description => "Plain text"},
    {name => "text",      mode => "text", description => "----------"},
    {name => "cobol",     mode => "cobol", description => "GnuCOBOL 2.2"},
    {name => "perl",      mode => "perl", description => "Perl 5 (blead/git)"},
    {name => "perlt",      mode => "perl", description => "Perl 5 (blead/git threaded)"},
    {name => "deparse",   mode => "perl", description => "Deparsed Perl"},
    {name => "evalall",   mode => "perl", description => "Perl (EvalAll) (major unthreaded)"},
    {name => "evaltall",   mode => "perl", description => "Perl (EvalAll) (major threaded)"},
    {name => "evalrall",   mode => "perl", description => "Perl (EvalAll) (major un+threaded)"},
    {name => "evalrall",   mode => "perl", description => "Perl (EvalY'All) (EVERYTHING)"},
    {name => "perl5.30.0", mode => "perl", description => "Perl 5.30.0"},
    {name => "perl5.30.0t", mode => "perl", description => "Perl 5.30.0 (threaded)"},
    {name => "perl5.28.2", mode => "perl", description => "Perl 5.28.2"},
    {name => "perl5.28.2t", mode => "perl", description => "Perl 5.28.2 (threaded)"},
    {name => "perl5.28.1", mode => "perl", description => "Perl 5.28.1"},
    {name => "perl5.28.1t", mode => "perl", description => "Perl 5.28.1 (threaded)"},
    {name => "perl5.28.0", mode => "perl", description => "Perl 5.28.0"},
    {name => "perl5.28.0t", mode => "perl", description => "Perl 5.28.0 (threaded)"},
    {name => "perl5.26.3", mode => "perl", description => "Perl 5.26.3"},
    {name => "perl5.26.3t", mode => "perl", description => "Perl 5.26.3 (threaded)"},
    {name => "perl5.26.2", mode => "perl", description => "Perl 5.26.2"},
    {name => "perl5.26.2t", mode => "perl", description => "Perl 5.26.2 (threaded)"},
    {name => "perl5.26.1", mode => "perl", description => "Perl 5.26.1"},
    {name => "perl5.26.1t", mode => "perl", description => "Perl 5.26.1 (threaded)"},
    {name => "perl5.26.0", mode => "perl", description => "Perl 5.26.0"},
    {name => "perl5.26.0t", mode => "perl", description => "Perl 5.26.0 (threaded)"},
    {name => "perl5.24.4", mode => "perl", description => "Perl 5.24.4"},
    {name => "perl5.24.4t", mode => "perl", description => "Perl 5.24.4 (threaded)"},
    {name => "perl5.24.3", mode => "perl", description => "Perl 5.24.3"},
    {name => "perl5.24.3t", mode => "perl", description => "Perl 5.24.3 (threaded)"},
    {name => "perl5.24.2", mode => "perl", description => "Perl 5.24.2"},
    {name => "perl5.24.2t", mode => "perl", description => "Perl 5.24.2 (threaded)"},
    {name => "perl5.24.1", mode => "perl", description => "Perl 5.24.1"},
    {name => "perl5.24.1t", mode => "perl", description => "Perl 5.24.1 (threaded)"},
    {name => "perl5.24.0", mode => "perl", description => "Perl 5.24.0"},
    {name => "perl5.24.0t", mode => "perl", description => "Perl 5.24.0 (threaded)"},
    {name => "perl5.22.4", mode => "perl", description => "Perl 5.22.4"},
    {name => "perl5.22.4t", mode => "perl", description => "Perl 5.22.4 (threaded)"},
    {name => "perl5.22.3", mode => "perl", description => "Perl 5.22.3"},
    {name => "perl5.22.3t", mode => "perl", description => "Perl 5.22.3 (threaded)"},
    {name => "perl5.22.2", mode => "perl", description => "Perl 5.22.2"},
    {name => "perl5.22.2t", mode => "perl", description => "Perl 5.22.2 (threaded)"},
    {name => "perl5.22.1", mode => "perl", description => "Perl 5.22.1"},
    {name => "perl5.22.1t", mode => "perl", description => "Perl 5.22.1 (threaded)"},
    {name => "perl5.22.0", mode => "perl", description => "Perl 5.22.0"},
    {name => "perl5.22.0t", mode => "perl", description => "Perl 5.22.0 (threaded)"},
    {name => "perl5.20.3", mode => "perl", description => "Perl 5.20.3"},
    {name => "perl5.20.3t", mode => "perl", description => "Perl 5.20.3 (threaded)"},
    {name => "perl5.20.2", mode => "perl", description => "Perl 5.20.2"},
    {name => "perl5.20.2t", mode => "perl", description => "Perl 5.20.2 (threaded)"},
    {name => "perl5.20.1", mode => "perl", description => "Perl 5.20.1"},
    {name => "perl5.20.1t", mode => "perl", description => "Perl 5.20.1 (threaded)"},
    {name => "perl5.20.0", mode => "perl", description => "Perl 5.20.0"},
    {name => "perl5.20.0t", mode => "perl", description => "Perl 5.20.0 (threaded)"},
    {name => "perl5.18.4", mode => "perl", description => "Perl 5.18.4"},
    {name => "perl5.18.4t", mode => "perl", description => "Perl 5.18.4 (threaded)"},
    {name => "perl5.18.3", mode => "perl", description => "Perl 5.18.3"},
    {name => "perl5.18.3t", mode => "perl", description => "Perl 5.18.3 (threaded)"},
    {name => "perl5.18.2", mode => "perl", description => "Perl 5.18.2"},
    {name => "perl5.18.2t", mode => "perl", description => "Perl 5.18.2 (threaded)"},
    {name => "perl5.18.1", mode => "perl", description => "Perl 5.18.1"},
    {name => "perl5.18.1t", mode => "perl", description => "Perl 5.18.1 (threaded)"},
    {name => "perl5.18.0", mode => "perl", description => "Perl 5.18.0"},
    {name => "perl5.18.0t", mode => "perl", description => "Perl 5.18.0 (threaded)"},
    {name => "perl5.16.3", mode => "perl", description => "Perl 5.16.3"},
    {name => "perl5.16.3t", mode => "perl", description => "Perl 5.16.3 (threaded)"},
    {name => "perl5.16.2", mode => "perl", description => "Perl 5.16.2"},
    {name => "perl5.16.2t", mode => "perl", description => "Perl 5.16.2 (threaded)"},
    {name => "perl5.16.1", mode => "perl", description => "Perl 5.16.1"},
    {name => "perl5.16.1t", mode => "perl", description => "Perl 5.16.1 (threaded)"},
    {name => "perl5.16.0", mode => "perl", description => "Perl 5.16.0"},
    {name => "perl5.16.0t", mode => "perl", description => "Perl 5.16.0 (threaded)"},
    {name => "perl5.14.4", mode => "perl", description => "Perl 5.14.4"},
    {name => "perl5.14.4t", mode => "perl", description => "Perl 5.14.4 (threaded)"},
    {name => "perl5.14.3", mode => "perl", description => "Perl 5.14.3"},
    {name => "perl5.14.3t", mode => "perl", description => "Perl 5.14.3 (threaded)"},
    {name => "perl5.14.2", mode => "perl", description => "Perl 5.14.2"},
    {name => "perl5.14.2t", mode => "perl", description => "Perl 5.14.2 (threaded)"},
    {name => "perl5.14.1", mode => "perl", description => "Perl 5.14.1"},
    {name => "perl5.14.1t", mode => "perl", description => "Perl 5.14.1 (threaded)"},
    {name => "perl5.14.0", mode => "perl", description => "Perl 5.14.0"},
    {name => "perl5.14.0t", mode => "perl", description => "Perl 5.14.0 (threaded)"},
    {name => "perl5.12.5", mode => "perl", description => "Perl 5.12.5"},
    {name => "perl5.12.5t", mode => "perl", description => "Perl 5.12.5 (threaded)"},
    {name => "perl5.12.4", mode => "perl", description => "Perl 5.12.4"},
    {name => "perl5.12.4t", mode => "perl", description => "Perl 5.12.4 (threaded)"},
    {name => "perl5.12.3", mode => "perl", description => "Perl 5.12.3"},
    {name => "perl5.12.3t", mode => "perl", description => "Perl 5.12.3 (threaded)"},
    {name => "perl5.12.2", mode => "perl", description => "Perl 5.12.2"},
    {name => "perl5.12.2t", mode => "perl", description => "Perl 5.12.2 (threaded)"},
    {name => "perl5.12.1", mode => "perl", description => "Perl 5.12.1"},
    {name => "perl5.12.1t", mode => "perl", description => "Perl 5.12.1 (threaded)"},
    {name => "perl5.12.0", mode => "perl", description => "Perl 5.12.0"},
    {name => "perl5.12.0t", mode => "perl", description => "Perl 5.12.0 (threaded)"},
    {name => "perl5.10.1", mode => "perl", description => "Perl 5.10.1"},
    {name => "perl5.10.1t", mode => "perl", description => "Perl 5.10.1 (threaded)"},
    {name => "perl5.10.0", mode => "perl", description => "Perl 5.10.0"},
    {name => "perl5.10.0t", mode => "perl", description => "Perl 5.10.0 (threaded)"},
    {name => "perl5.8.9", mode => "perl", description => "Perl 5.8.9"},
    {name => "perl5.8.9t", mode => "perl", description => "Perl 5.8.9 (threaded)"},
    {name => "perl5.8.8", mode => "perl", description => "Perl 5.8.8"},
    {name => "perl5.8.8t", mode => "perl", description => "Perl 5.8.8 (threaded)"},
    {name => "perl5.8.7", mode => "perl", description => "Perl 5.8.7"},
    {name => "perl5.8.7t", mode => "perl", description => "Perl 5.8.7 (threaded)"},
    {name => "perl5.8.6", mode => "perl", description => "Perl 5.8.6"},
    {name => "perl5.8.6t", mode => "perl", description => "Perl 5.8.6 (threaded)"},
    {name => "perl5.8.5", mode => "perl", description => "Perl 5.8.5"},
    {name => "perl5.8.5t", mode => "perl", description => "Perl 5.8.5 (threaded)"},
    {name => "perl5.8.4", mode => "perl", description => "Perl 5.8.4"},
    {name => "perl5.8.4t", mode => "perl", description => "Perl 5.8.4 (threaded)"},
    {name => "perl5.8.3", mode => "perl", description => "Perl 5.8.3"},
    {name => "perl5.8.3t", mode => "perl", description => "Perl 5.8.3 (threaded)"},
    {name => "perl5.8.2", mode => "perl", description => "Perl 5.8.2"},
    {name => "perl5.8.2t", mode => "perl", description => "Perl 5.8.2 (threaded)"},
    {name => "perl5.8.1", mode => "perl", description => "Perl 5.8.1"},
    {name => "perl5.8.1t", mode => "perl", description => "Perl 5.8.1 (threaded)"},
    {name => "perl5.8.0", mode => "perl", description => "Perl 5.8.0"},
    {name => "perl5.8.0t", mode => "perl", description => "Perl 5.8.0 (threaded)"},
    {name => "perl5.6.2", mode => "perl", description => "Perl 5.6.2"},
    {name => "perl5.6.2t", mode => "perl", description => "Perl 5.6.2 (threaded)"},
    {name => "perl5.6.1", mode => "perl", description => "Perl 5.6.1"},
    {name => "perl5.6.1t", mode => "perl", description => "Perl 5.6.1 (threaded)"},
    {name => "perl5.6.0", mode => "perl", description => "Perl 5.6.0"},
    {name => "perl5.6.0t", mode => "perl", description => "Perl 5.6.0 (threaded)"},
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
