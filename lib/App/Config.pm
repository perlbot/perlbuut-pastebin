package App::Config;

use strict;
use warnings;

use Exporter qw/import/;
use Data::Dumper;
use FindBin qw($Bin);

use TOML;

our @EXPORT=qw/$cfg/;

our $cfg = do {
    my $toml = do {open(my $fh, "<", "$Bin/app.cfg"); local $/; <$fh>};
# With error checking
    my ($data, $err) = from_toml($toml);
    unless ($data) {
            die "Error parsing toml: $err";
    }
    $data;
};

1;
