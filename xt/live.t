use strict;
use warnings;
use Encode qw(decode encode);
use Geo::Coder::SimpleGeo;
use Test::More;

unless ($ENV{SIMPLEGEO_KEY} and $ENV{SIMPLEGEO_SECRET}) {
    plan skip_all => 'SIMPLEGEO_KEY and SIMPLEGEO_SECRET environment'
        . ' variables must be set';
}
else {
    plan tests => 2;
}

my $debug = $ENV{GEO_CODER_SIMPLEGEO_DEBUG};
unless ($debug) {
    diag "Set GEO_CODER_SIMPLEGEO_DEBUG to see request/response data";
}

my $geocoder = Geo::Coder::SimpleGeo->new(
    key    => $ENV{SIMPLEGEO_KEY},
    secret => $ENV{SIMPLEGEO_SECRET},
    debug  => $debug,
);

{
    my $address = '41 Decatur St, San Francisco, CA';
    my $location = $geocoder->geocode($address);
    like(
        $location->{properties}{zip},
        qr/^94103/,
        "correct zip code for $address"
    );
}
{
    my @locations = $geocoder->geocode('Main Street, Los Angeles, CA');
    ok(@locations > 1, 'there are many Main Streets in Los Angeles, CA');
}
