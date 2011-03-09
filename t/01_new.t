use strict;
use warnings;
use Test::More tests => 3;
use Geo::Coder::SimpleGeo;

new_ok(
    'Geo::Coder::SimpleGeo' => [ token => 'Your JSONP token', ]
);

{
    local $@;
    eval {
        my $geocoder = Geo::Coder::SimpleGeo->new(debug => 1);
    };
    like($@, qr/^'token' is required/, 'token is required');
}

can_ok('Geo::Coder::SimpleGeo', qw(geocode response ua));
