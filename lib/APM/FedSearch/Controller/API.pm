package APM::FedSearch::Controller::API;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use Carp;
use JSON;
use Data::Dump qw( dump );
use Search::OpenSearch;
use Time::HiRes qw( time );
use Module::Load ();

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
    my $model = $c->model( $self->api_model );
    if ( !$model ) {
        croak "No such model " . $self->api_model;
    }
    my $res = $model->about( $c->request );
    $c->response->body( encode_json($res) );
}

sub search : Local {
    my ( $self, $c, @args ) = @_;
    my $request = $c->request;
    if ( @args or $request->method ne 'GET' ) {

        # we do not support click-through-to-result like dezi does
        $c->response->code(400);
        $c->response->body(
            encode_json( { 'success' => 0, error => 'Invalid request' } ) );
        return;

    }

    my $start_time = time();
    my $model      = $c->model( $self->api_model );
    if ( !$model ) {
        croak "No such model " . $self->api_model;
    }
    my $res = $model->search($request);

    # check for user errors
    if ( $res->{error} ) {
        $c->response->body(
            encode_json( { 'success' => 0, error => $res->{error} } ) );
        return;
    }

    #dump $res;

    # we should return the format that was requested
    my $sos_response_class = 'Search::OpenSearch::Response::' . $res->{type};
    eval { Module::Load::load($sos_response_class); };
    if ($@) {
        $c->log->error($@);
        $c->response->body(
            encode_json(
                {   'success' => 0,
                    'error'   => "Unsupported response type $res->{type}"
                }
            )
        );
        return;
    }
    my $sos_response;
    eval {
        $sos_response = $sos_response_class->new(
            search_time  => sprintf( "%0.5f", time() - $start_time ),
            build_time   => sprintf( "%0.5f", time() - $start_time ),
            results      => $res->{results},
            author       => 'APM Federated Search API',
            engine       => __PACKAGE__,
            version      => $APM::FedSearch::VERSION,
            total        => $res->{total},
            page_size    => $res->{p},
            offset       => $res->{o},
            query        => $res->{q},
            parsed_query => $res->{q},
            fields       => $model->fields,
        );
    };
    if ($@) {
        $c->log->error($@);
        $c->response->body(
            encode_json( { 'success' => 0, error => 'Server error' } ) );
        return;
    }
    $c->stash( response => { content_type => $sos_response->content_type } );
    $c->response->body("$sos_response");

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

=head1 COPYRIGHT

Copyright 2012 - American Public Media Group

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
