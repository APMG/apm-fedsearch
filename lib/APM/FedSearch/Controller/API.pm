package APM::FedSearch::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use Carp;
use JSON;
use Data::Dump qw( dump );
use Search::OpenSearch;
use Search::OpenSearch::Response::JSON;

#use Time::HiRes qw( time );

has api_model => ( is => 'rw' );

=head1 NAME

APM::FedSearch::Controller::API - search API

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

around BUILD => sub {
    my $orig = shift;
    my ( $self, $args ) = @_;
    $self->$orig($args) if ref($self);
    if ( !$self->api_model ) {
        $self->api_model('API');
    }
    return $self;
};

=head2 index

The root page (/)

=cut

# /         -> About
# /search   -> GET only

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

}

sub search : Local {
    my ( $self, $c ) = @_;
    my $request  = $c->request;
    my $res = $c->model( $self->api_model )->search( $request );
}

=head2 default

Standard 404 error page

=cut

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->body('Page not found');
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ( $self, $c ) = @_;
    $c->response->content_type( $c->stash->{response}->{content_type}
            || 'application/json' );
}

=head1 AUTHOR

Catalyst developer

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
