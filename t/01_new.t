use strict;
use warnings;
use Test::More tests => 3;
use Geo::Coder::SimpleGeo;

new_ok(
    'Geo::Coder::SimpleGeo' => [
        key    => 'Your Key',
        secret => 'Your Secret'
    ]
);

{
    local $@;
    eval {
        my $geocoder = Geo::Coder::SimpleGeo->new(debug => 1);
    };
    like(
        $@, qr/^'key' and 'secret' are required/,
        'key/secret are required'
    );
}

can_ok('Geo::Coder::SimpleGeo', qw(geocode response ua));
