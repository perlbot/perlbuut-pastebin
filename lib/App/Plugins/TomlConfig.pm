package App::Plugins::TomlConfig;
use Mojo::Base 'Mojolicious::Plugin::Config';

use v5.24;
use strict;
use warnings;

use Data::Dumper;

use TOML;
use Hash::Merge;
use Syntax::Keyword::Try;
use Path::Tiny;

sub parse {
  my ($self, $content, $file, $conf, $app) = @_;

  my $merged_config;

  try {
    my $env_file = path($file)->child($env.".cfg");
    my $base_file = path($file)->child('base.cfg');

    my $base_config_data = $base_file->slurp_utf8();
    my $env_config_data = $env_file->slurp_utf8();

    my ($base_config, $base_error) = from_toml($base_config_data);
    die "$base_file: $base_error" if $base_error;
  
    my $env_config  = from_toml($env_config_data);
    die "$env_file: $env_error" if $env_error;

    $merged_config = merge($base_config, $env_config);
  } catch($e) {
    die "Unable to process config file: $e";
  }

  die Dumper($merged_config);
  return $merged_config;
}

# TODO figure out what i want here
sub register { shift->SUPER::register(shift, {%{shift()}}) }


1;
