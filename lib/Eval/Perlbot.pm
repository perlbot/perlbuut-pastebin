package Eval::Perlbot;

use strict;
use warnings;
use v5.22;

use Exporter qw/import/;
our @EXPORT=qw/get_eval/;

use Encode qw/decode/;
use POE::Filter::Reference;

use App::Config;
use App::Memcached;

sub get_eval {
    my ($paste_id, $code) = @_;
   
    if (my $cached = $memd->get($paste_id)) {
        return $cached;
    } else {
        my $filter = POE::Filter::Reference->new();
        my $socket = IO::Socket::INET->new(  PeerAddr => $cfg->{evalserver}{server} //'localhost', PeerPort => $cfg->{evalserver}{port} //14400 )
            or die "error: cannot connect to eval server";

        my $refs = $filter->put( [ { code => "perl $code" } ] ); # TODO make this support other langs

        print $socket $refs->[0]; 
        my $output = do {local $/; <$socket>};
        close $socket;
        my $result = $filter->get( [ $output ] );
        my $str = eval {decode("utf8", $result->[0]->[0])} // $result->[0]->[0];
        $str = eval {decode("utf8", $str)} // $str; # I don't know why i need to decode this twice.  shurg.
        $memd->set($paste_id, $str);

        return $str;
    }
}
