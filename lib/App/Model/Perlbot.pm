package IRC::Perlbot;

use strict;
use warnings;
use v5.22;
use Data::Dumper;

#use Exporter qw/import/;
#our @EXPORT=qw/get_eval/;

use App::Config;

sub announce {
    my ($channel, $who, $what, $link) = @_;

    print Dumper($cfg->{announce});

    my $socket = IO::Socket::INET->new(  PeerAddr => $cfg->{announce}{server} //'localhost', PeerPort => $cfg->{announce}{port} //1784 )
        or die "error: cannot connect to announce server";

    print $socket "$channel\x1E$link\x1E$who\x1E$what\n";
    close($socket);
}

1;
