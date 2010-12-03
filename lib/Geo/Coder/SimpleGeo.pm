package Geo::Coder::SimpleGeo;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use Net::OAuth;
use URI;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

sub new {
    my ($class, %params) = @_;

    croak q('key' and 'secret' are required)
        unless $params{key} and $params{secret};

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }

    $self->{compress} = 1 unless exists $self->{compress};
    $self->ua->default_header(accept_encoding => 'gzip,deflate')
        if $self->{compress};

    return $self;
}

sub response { $_[0]->{response} }

sub ua {
    my ($self, $ua) = @_;
    if ($ua) {
        croak q('ua' must be (or derived from) an LWP::UserAgent')
            unless ref $ua and $ua->isa(q(LWP::UserAgent));
        $self->{ua} = $ua;
    }
    return $self->{ua};
}

sub geocode {
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (location => @params) : @params;

    my $location = $params{location} or return;
    $location = Encode::decode('utf-8', $location);

    my $uri = URI->new('http://api.simplegeo.com/0.1/geocode/address.json');
    $uri->query_form(
        q => $location,
    );

    my $req = Net::OAuth->request('consumer')->new(
        consumer_key     => $self->{key},
        consumer_secret  => $self->{secret},
        request_method   => 'GET',
        request_url      => $uri,
        signature_method => 'HMAC-SHA1',
        timestamp        => time,
        nonce            => $$ . int(rand(2**32)),
    );
    $req->sign;

    my $res = $self->{response} = $self->ua->get(
        $req->to_url,
        authorization => $req->to_authorization_header,
    );
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $data = eval { from_json($res->decoded_content) };
    return unless $data;

    my @results = @{ $data->{features} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::SimpleGeo - Geocode addresses with the SimpleGeo API

=head1 SYNOPSIS

    use Geo::Coder::SimpleGeo;

    my $geocoder = Geo::Coder::SimpleGeo->new(
        key    => 'Your Key',
        secret => 'Your Secret',
    );
    my $location = $geocoder->geocode(
        location => '425 W Randolph St, Chicago, IL'
    );

=head1 DESCRIPTION

The C<Geo::Coder::SimpleGeo> module provides an interface to the geocoding
functionality of the SimpleGeo API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::SimpleGeo->new(
        key    => 'Your Key',
        secret => 'Your Secret',
        # debug  => 1,
    )

Creates a new geocoding object.

A key and secret can be obtained here:
L<http://simplegeo.com/account/settings/>

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        geometry => {
            coordinates => [ "-122.406032", "37.772502" ],
            type        => "Point"
        },
        properties => {
            number    => 41,
            precision => "range",
            prenum    => "",
            score     => "0.805",
            street    => "Decatur St",
            zip       => 94103,
        },
        type => "Feature",
    }

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://simplegeo.com/docs/>

L<Geo::Coder::Bing>, L<Geo::Coder::Bing::Bulk>, L<Geo::Coder::Google>,
L<Geo::Coder::Mapquest>, L<Geo::Coder::Multimap>, L<Geo::Coder::Navteq>,
L<Geo::Coder::OSM>, L<Geo::Coder::PlaceFinder>, L<Geo::Coder::TomTom>,
L<Geo::Coder::Yahoo>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-SimpleGeo>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::SimpleGeo

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-simplegeo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-SimpleGeo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-SimpleGeo>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-SimpleGeo>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-SimpleGeo>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
