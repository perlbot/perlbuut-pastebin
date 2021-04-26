package App::Config;

use v5.24;
use strict;
use warnings;

use Exporter qw/import/;
use Data::Dumper;
use FindBin qw($Bin);

use TOML;
use Hash::Merge qw/merge/;
use Syntax::Keyword::Try;
use Path::Tiny;

our @EXPORT=qw/$cfg/;

my $cfg_dir = path($Bin)->child('etc');

our $env = $ENV{MOJO_MODE} // $ENV{PLACK_ENV} // "development";

warn "Loading $env configs";

our $cfg = do {
  my $merged_config;

  try {
    my $env_file = path($cfg_dir)->child($env.".cfg");
    my $base_file = path($cfg_dir)->child('base.cfg');

    my $base_config_data = $base_file->slurp_utf8();
    my $env_config_data = $env_file->slurp_utf8();

    my ($base_config, $base_error) = from_toml($base_config_data);
    die "$base_file: $base_error" if $base_error;
  
    my ($env_config, $env_error)  = from_toml($env_config_data);
    die "$env_file: $env_error" if $env_error;

    $merged_config = merge($base_config, $env_config);
  } catch($e) {
    die "Unable to process config file: $e";
  }

  $merged_config;
};

sub get_config {
  my $key = shift;

  return $cfg->{$key};
}

1;
