package App::Spamfilter;

use strict;
use warnings;
use App::Config;

sub is_spam {
    my ($c, $who, $what, $code) = @_;

    if ($cfg->{features}{blogspam}) {
        my $blogspam = $c->blogspam(
            comment => $code,
            subject => $what,
            name => $who
        );

        return 1 unless ($blogspam->test_comment());
    }

    return 2 if ($who =~ /^[A-Z]\w+\s+[A-Z]\w+$/); # block proper names, probably spam
    return 3 if ($what =~ m|https?://|); # no links in the desc, maybe relax later
    return 0; # we thought it wasn't spam
}

1;
