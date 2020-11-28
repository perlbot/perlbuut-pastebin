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

    return if (length($who) > 16);

    printf "Sending to %s:%s = %s\n", $self->config->{host}, $self->config->{port}, "$channel\x1E$link\x1E$who\x1E$what\n";
    my $socket = IO::Socket::INET->new(  PeerAddr => $self->config->{host}, PeerPort => $self->config->{port} )
        or die "error: cannot connect to announce server: $! ".$self->config->{host} . ":" .$self->config->{port};


    print $socket "$channel\x1E$link\x1E$who\x1E$what\n";
    close($socket);
}

1;
