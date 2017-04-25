package App::Model::Perlbot;

use strict;
use warnings;
use v5.22;
use Data::Dumper;

use Mojo::Base '-base';

has config => sub {App::Config::get_config('announce')};

sub announce {
    my $self = shift;
    my ($channel, $who, $what, $link) = @_;

    my $socket = IO::Socket::INET->new(  PeerAddr => $self->config->{server} //'localhost', PeerPort => $self->config->{port} //1784 )
        or die "error: cannot connect to announce server";

    print $socket "$channel\x1E$link\x1E$who\x1E$what\n";
    close($socket);
}

1;
