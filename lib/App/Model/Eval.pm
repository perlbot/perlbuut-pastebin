package App::Model::Eval;

use strict;
use warnings;
use v5.22;

use Mojo::Base '-base';

use Encode qw/decode/;
use POE::Filter::Reference;

use App::Config;
use App::Memcached;

has cfg => sub {App::Config::get_config('evalserver')}; 

sub get_eval {
    my ($self, $paste_id, $code, $lang) = @_;
   
    if ($paste_id && (my $cached = $memd->get($paste_id))) {
        return $cached;
    } else {
        my $filter = POE::Filter::Reference->new();
        my $socket = IO::Socket::INET->new(  PeerAddr => $self->cfg->{server} //'localhost', PeerPort => $self->cfg->{port} //14400 )
            or die "error: cannot connect to eval server";

        $lang //= "perl";
        return undef if ($lang eq 'text');

        my $refs = $filter->put( [ { code => $lang . " $code" } ] );

        print $socket $refs->[0]; 
        my $output = do {local $/; <$socket>};
        close $socket;
        my $result = $filter->get( [ $output ] );
        my $str = eval {decode("utf8", $result->[0]->[0])} // $result->[0]->[0];
        $str = eval {decode("utf8", $str)} // $str; # I don't know why i need to decode this twice.  shurg.
        $memd->set($paste_id, $str) if ($paste_id);

        return $str;
    }
}

1;
