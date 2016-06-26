package App::Memcached;

use strict;
use warnings;
no warnings "experimental::postderef";
use feature "postderef", "postderef_qq";

use App::Config;
use Exporter qw/import/;

our @EXPORT = qw/$memd/;

our $memd;

if ($cfg->{features}{memcached}) {
    my $namespace = delete $cfg->{memcached}{namespace};
    $namespace .= "_".time() if (delete $cfg->{memcached}{unique_namespace});

    # Only load these if we're using them
    require Cache::Memcached::Fast;
    require IO::Compress::Gzip;
    require IO::Uncompress::Gunzip;
    $memd = Cache::Memcached::Fast->new({
        namespace => $namespace // 'pastebin',
        connect_timeout => 0.2,
        io_timeout => 0.5,
        close_on_error => 1,
        compress_threshold => 1_000,
        compress_ratio => 0.9,
        compress_methods => [ \&IO::Compress::Gzip::gzip,
                              \&IO::Uncompress::Gunzip::gunzip ],
        max_failures => 3,
        failure_timeout => 2,
        ketama_points => 150,
        nowait => 1,
        hash_namespace => 1,
        serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
        utf8 => 1,
        max_size => 512 * 1024,
        $cfg->{memcached}->%*, # let the config overwrite anything set here if they want
    });
} else {
    $memd = bless {}, "App::Memcached::_mock";
}

# a mock object that does nothing but pretends to be the two functions i need
package App::Memcached::_mock;

sub get {
}

sub set {
}
