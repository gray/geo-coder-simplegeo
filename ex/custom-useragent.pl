#!/usr/bin/env perl
use strict;
use warnings;

use Data::Dumper;
use Geo::Coder::SimpleGeo;

unless ($ENV{SIMPLEGEO_KEY} and $ENV{SIMPLEGEO_SECRET}) {
    die 'Set SIMPLEGEO_KEY and SIMPLEGEO_SECRET environment variables';
}
my $location = join(' ', @ARGV) || die "Usage: $0 \$location_string";

# Custom useragent identifier.
my $ua = LWP::UserAgent->new(agent => 'My Geocoder');

# Load any proxy settings from environment variables.
$ua->env_proxy;

my $geocoder = Geo::Coder::SimpleGeo->new(
    key    => $ENV{SIMPLEGEO_KEY},
    secret => $ENV{SIMPLEGEO_SECRET},
    ua     => $ua,
    debug  => 1,
);
my $result = $geocoder->geocode(location => $location);

local $Data::Dumper::Indent = 1;
print Dumper($result);
