package Geo::Coder::SimpleGeo;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.05';
$VERSION = eval $VERSION;

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (token => @params) : @params;

    croak q('token' is required) unless $params{token};

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
        $self->{compress} ||= 0;
    }
    if (exists $self->{compress} ? $self->{compress} : 1) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    croak q('https' requires LWP::Protocol::https)
        if $params{https} and not $self->ua->is_protocol_supported('https');

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
    my $raw = delete $params{raw};

    my $location = $params{location} or return;
    $location = Encode::decode('utf-8', $location);

    my $uri = URI->new('http://api.simplegeo.com/1.0/context/address.json');
    $uri->query_form(
        token   => $self->{token},
        address => $location,
        filter  => 'query,address',
    );
    $uri->scheme('https') if $self->{https};

    my $res = $self->{response} = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $data = eval { from_json($res->decoded_content) };
    return unless $data;
    return $data if $raw;

    # Currently only returns a single result...
    my @results = 'ARRAY' eq ref $data ? @$data : ($data);
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::SimpleGeo - Geocode addresses with the SimpleGeo API

=head1 SYNOPSIS

    use Geo::Coder::SimpleGeo;

    my $geocoder = Geo::Coder::SimpleGeo->new(
        token => 'Your SimpleGeo JSONP token'
    );
    my $location = $geocoder->geocode(
        location => '41 Decatur St, San Francisco, California 94103',
    );

=head1 DESCRIPTION

The C<Geo::Coder::SimpleGeo> module provides an interface to the geocoding
functionality of the SimpleGeo API.

Note: as of version 0.05, this module makes use of the new context service,
which replaces the original, and discontinued, geocode service.

Note: as of version 0.02, OAuth autorization has been replaced by the use of
the new JSONP token.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::SimpleGeo->new(
        token => 'Your SimpleGeo JSONP token',
        # https => 1,
        # debug => 1,
    )

Creates a new geocoding object.

Accepts the following named arguments:

=over

=item * I<token>

A JSONP token. (required)

A token can be obtained here: L<http://simplegeo.com/tokens/jsonp/>

=item * I<ua>

A custom LWP::UserAgent object. (optional)

=item * I<compress>

Enable compression. (default: 1, unless I<debug> is enabled)

=item * I<https>

Use https protocol for securing network traffic. (default: 0)

=item * I<debug>

Enable debugging. This prints the headers and content for requests and
responses. (default: 0)

=back

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        address => {
            geometry => {
                coordinates => [ "-122.406049843623", "37.7724651361945" ],
                type        => "Point",
            },
            properties => {
                address  => "65 Decatur St",
                city     => "San Francisco",
                country  => "US",
                county   => "San Francisco",
                distance => "0.01",
                postcode => 94103,
                province => "CA",
            },
            type => "Feature",
        },
        query => {
            address   => "41 Decatur St, San Francisco, California 94103",
            latitude  => "37.772555",
            longitude => "-122.405978",
        },
        timestamp => "1309346653.669",
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

L<http://search.cpan.org/dist/Geo-Coder-SimpleGeo/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
