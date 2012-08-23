package APM::FedSearch::MultiSearch;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use Parallel::Iterator qw( iterate_as_array );
use JSON;
use LWP::UserAgent;
use Scalar::Util qw( blessed );
use Search::Tools::XML;
use Data::Transformer;

# TODO release to CPAN under a different name

# we do not use WWW::OpenSearch because we need to pull out
# some non-standard data from the XML.
# we do use XML::Feed to parse XML responses.
use XML::Simple;
use XML::Feed;

my $OS_NS = 'http://a9.com/-/spec/opensearch/1.1/';

my $XMLer = Search::Tools::XML->new();

my $XML_ESCAPER = Data::Transformer->new(
    normal => sub { local ($_) = shift; $$_ = $XMLer->escape($$_); } );

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

sub total {
    return shift->{total};
}

sub _aggregate {
    my $self      = shift;
    my $responses = shift;
    my $results   = [];
    my $fields    = $self->fields;
    my $total     = 0;

RESP: for my $resp (@$responses) {

        #warn sprintf( "response for %s\n", $resp->request->uri );
        if ( $resp->content_type eq 'application/json' ) {
            my $r = decode_json( $resp->content );
            push @$results, @{ $r->{results} };
            $total += $r->{total};
        }
        if ( $resp->content_type eq 'application/xml' ) {
            my $xml = $resp->content;

            #warn $xml;
            my $feed = XML::Feed->parse( \$xml );

            if ( !$feed ) {
                warn XML::Feed->errstr;
                next RESP;
            }

            #dump $feed;

            #
            # we must re-escape the XML content since the feed parser
            # and XML::Simple will esacpe values automatically
            #
            my @entries;
            for my $item ( $feed->entries ) {
                my $e = {};
                for my $f (@$fields) {
                    $e->{$f} = $item->$f;
                    if ( blessed( $e->{$f} ) ) {

                        #dump( $e->{$f} );
                        if ( $e->{$f}->isa('XML::Feed::Content') ) {
                            $e->{$f} = $XMLer->escape( $e->{$f}->body );
                        }
                        elsif ( $e->{$f}->isa('DateTime') ) {
                            $e->{$f} = $e->{$f}->epoch;
                        }
                    }
                    else {
                        $e->{$f} = $XMLer->escape( $e->{$f} );
                    }
                }

                #dump $e;
                my $content = $item->content;
                my $fields = XMLin( $content->body, NoAttr => 1 );

                #dump $fields;

                for my $f ( keys %$fields ) {
                    $e->{$f} = $fields->{$f};
                    if ( ref $e->{$f} ) {
                        $XML_ESCAPER->traverse( $e->{$f} );
                    }
                    else {
                        $e->{$f} = $XMLer->escape( $e->{$f} );
                    }
                }

                # massage some field names
                $e->{mtime} = delete $e->{modified};
                $e->{uri}   = delete $e->{id};

                #dump $content;
                #dump $e;
                push @entries, $e;

            }

            my $atom = $feed->{atom};
            $total += $atom->get( $OS_NS, 'totalResults' );

            push @$results, @entries;
        }
    }
    $self->{total} = $total;
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
