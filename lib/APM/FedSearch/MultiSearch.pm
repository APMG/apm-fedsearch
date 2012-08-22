package APM::FedSearch::MultiSearch;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Parallel::Iterator qw( iterate_as_array );
use JSON;
use LWP::UserAgent;

# we do not use WWW::OpenSearch because it does more than we need
# but we do use XML::Feed to parse XML responses
use XML::Simple;
use XML::Feed;

sub new {
    my $class = shift;
    my %args  = @_;
    $args{fields} ||= [qw( title id author link summary tags modified )];
    return bless \%args, $class;
}

sub search {
    my $self = shift;

    my $urls     = $self->{urls} or croak "no urls defined";
    my $num_urls = scalar @$urls;
    my @done     = iterate_as_array(
        sub {
            $self->_fetch( $_[1] );
        },
        $urls,
    );

    return $self->_aggregate( \@done );

}

sub fields {
    return shift->{fields};
}

sub _aggregate {
    my $self      = shift;
    my $responses = shift;
    my $results   = [];
    my $fields    = $self->fields;

    for my $resp (@$responses) {

        #warn sprintf( "response for %s\n", $resp->request->uri );
        if ( $resp->content_type eq 'application/json' ) {
            my $r = decode_json( $resp->content );
            push @$results, @{ $r->{results} };
        }
        if ( $resp->content_type eq 'application/xml' ) {
            my $xml = $resp->content;

            #warn $xml;
            my $feed = XML::Feed->parse( \$xml );

            #dump $feed;
            my @entries;
            for my $item ( $feed->entries ) {
                my $e = {};
                for my $f (@$fields) {
                    $e->{$f} = $item->$f;
                }
                my $content = $item->content;
                my $fields  = XMLin( $content->body );

                #dump $fields;
                for my $f ( keys %$fields ) {
                    $e->{$f} = $fields->{$f};
                }

                #dump $content;
                #dump $e;
                push @entries, $e;

            }

            push @$results, @entries;
        }
    }
    return [ sort { $b->{score} <=> $a->{score} } @$results ];
}

sub _fetch {
    my $self = shift;
    my $url  = shift or croak "url required";
    my $ua   = LWP::UserAgent->new();
    $ua->agent('apm-fedsearch');
    $ua->timeout( $self->{timeout} ) if $self->{timeout};

    my $response = $ua->get($url);

    #warn "got response for $url: " . $response->status_line;
    return $response;
}

1;

__END__

=head1 NAME

APM::FedSearch::MultiSearch - search OpenSearch servers in parallel

=head1 SYNOPSIS

 my $ms = APM::FedSearch::MultiSearch->new(
    urls    => [
        'http://someplace.org/search?q=foo',
        'http://someother.org/search?q=foo',
    ],
    timeout => 10,  # very generous
 );

 my $results = $ms->search();
 for my $r (@$results) {
     printf("title=%s", $r->title);
     printf("uri=%s",   $r->uri);
     print "\n";
 }

=head1 METHODS

=head2 new( I<args> )

Constructor. I<args> should include key C<urls> with value of
an array reference.

=head2 search

Execute the search. Returns array ref of results sorted by score.

=head1 COPYRIGHT

Copyright 2012 - American Public Media Group

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
