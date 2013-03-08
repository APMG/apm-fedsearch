package APM::FedSearch::MultiSearch;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use base 'Search::OpenSearch::Federated';

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
