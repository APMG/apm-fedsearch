package APM::FedSearch::Model::API;
use strict;
use warnings;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Model' }

has urls => ( is => 'rw', isa => 'ArrayRef', required => 1, );
has fields => ( is => 'rw', isa => 'ArrayRef' );
has facets => ( is => 'rw', isa => 'ArrayRef' );

use Carp;
use JSON;
use Data::Dump qw( dump );
use Search::OpenSearch::Response::JSON;
use APM::FedSearch::MultiSearch;

sub about {
    my ( $self, $request ) = @_;
    my $uri   = $request->uri;
    my $about = {
        name         => 'APM Federated Search',
        author       => 'APMG',
        api_base_url => "$uri",
        api_format   => [qw( JSON ExtJS XML )],
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
    my $type      = $p->{t} || $p->{format} || 'XML';
    my $offset    = $p->{o} || 0;
    my $page_size = $p->{p} || 25;

    # TODO sorting

    # TODO test paging (our math is naive)

    my $urls = $self->urls;
    for my $url (@$urls) {
        $url .= sprintf( '?q=%s&t=%s&o=%d&p=%d',
            $q, $type, $offset, int( $page_size / scalar(@$urls) ) );
    }

    my $ms = APM::FedSearch::MultiSearch->new( urls => $urls );
    my $results = $ms->search();
    return {
        results => $results,
        type    => $type,
        total   => $ms->total(),
        p       => $page_size,
        o       => $offset,
        q       => $q,
    };
}

1;
