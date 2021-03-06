package APM::FedSearch::Model::API;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Model' }

has base_uri => ( is => 'rw' );
has urls => ( is => 'rw', isa => 'ArrayRef', required => 1, );
has fields => ( is => 'rw', isa => 'ArrayRef' );
has facets => ( is => 'rw', isa => 'ArrayRef' );

use Carp;
use JSON;
use Data::Dump qw( dump );
use Search::OpenSearch::Response::JSON;
use Search::OpenSearch::Federated;

sub about {
    my ( $self, $request ) = @_;
    my $uri = $self->base_uri || $request->uri;
    my $about = {
        name         => 'APM Federated Search',
        author       => 'American Public Media',
        api_base_url => "$uri",
        api_format   => [qw( JSON ExtJS XML Tiny )],
        methods      => [
            {   method      => 'GET',
                path        => '/search',
                params      => [qw( q r c f o s p t u )],
                required    => [qw( q )],
                description => 'return search results',
                base_url    => "$uri",
            }
        ],
        description =>
            'APM Federated Search provides search results across multiple domains.',
        version => $APM::FedSearch::VERSION,
        fields  => $self->fields,
        facets  => $self->facets,
    };
    return $about;
}

sub search {
    my ( $self, $request ) = @_;

    my $p         = $request->parameters;
    my $q         = $p->{q};
    my $type      = $p->{t} || $p->{format} || 'JSON';
    my $offset    = $p->{o} || 0;
    my $page_size = $p->{p} || 10;
    my $sort      = $p->{s} || 'score desc';

    if ( !defined $q or !length $q ) {
        return { error => 'q param required', };
    }

    # make a copy of base config each time
    my $urls = [ @{ $self->urls } ];

    for my $url (@$urls) {
        $url .= sprintf( '?q=%s&t=%s&o=%d&p=%d&s=%s',
            $q, $type, $offset, $page_size, $sort );
    }

    #dump $urls;

    my $ms = Search::OpenSearch::Federated->new(
        urls             => $urls,
        normalize_scores => 1,
    );

    my $results = $ms->search();

    return {
        results   => $results,
        type      => $type,
        facets    => $ms->facets(),
        subtotals => $ms->subtotals(),
        total     => $ms->total(),
        p         => ( $page_size * scalar(@$urls) ),
        o         => $offset,
        q         => $q,
        s         => $sort,
    };
}

1;

=head1 COPYRIGHT

Copyright 2012 - American Public Media Group

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
