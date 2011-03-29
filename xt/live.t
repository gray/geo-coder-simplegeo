use strict;
use warnings;
use Encode qw(decode encode);
use Geo::Coder::SimpleGeo;
use Test::More;

plan skip_all => 'SIMPLEGEO_TOKEN environment variables must be set'
    unless $ENV{SIMPLEGEO_TOKEN};

my $debug = $ENV{GEO_CODER_SIMPLEGEO_DEBUG};
unless ($debug) {
    diag "Set GEO_CODER_SIMPLEGEO_DEBUG to see request/response data";
}

my $has_ssl = LWP::UserAgent->is_protocol_supported('https');

my $geocoder = Geo::Coder::SimpleGeo->new(
    token => $ENV{SIMPLEGEO_TOKEN},
    debug => $debug,
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

SKIP: {
    skip 'no SSL support', 1 unless $has_ssl;
    my $geocoder = Geo::Coder::SimpleGeo->new(
        token => $ENV{SIMPLEGEO_TOKEN},
        debug => $debug,
        https  => 1,
    );
    my $address = '41 Decatur St, San Francisco, CA';
    my $location = $geocoder->geocode($address);
    like($location->{properties}{zip}, qr/^94103/, "https");
}

done_testing;
