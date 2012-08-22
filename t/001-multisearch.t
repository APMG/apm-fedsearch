#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 6;
use Data::Dump qw( dump );
use lib 'lib';

use APM::FedSearch::MultiSearch;

my $type = $ENV{SOS_TYPE} || 'XML';

ok( my $ms = APM::FedSearch::MultiSearch->new(
        urls => [
            "http://pkarmanpc.mpr.org:5000/search?f=0&q=test&t=$type",
            "http://pkarmanpc.mpr.org:5000/search?f=0&q=turkey&t=$type",
        ],
        timeout => 5,
    ),
    "new MultiSearch object"
);

ok( my $resp = $ms->search(), "search()" );

#dump($resp);

is( ref($resp), 'ARRAY', "response is an ARRAY ref" );

ok( scalar(@$resp) > 1, "more than one result" );

ok( $resp->[0]->{score}, "first result has a score" );

my $prev_score;
my $failed_sort = 0;
R: for my $r (@$resp) {
    if ( !defined $prev_score ) {
        $prev_score = $r->{score};
    }
    if ( $r->{score} > $prev_score ) {
        $failed_sort = 1;
        last R;
    }
    $prev_score = $r->{score};
}

ok( !$failed_sort, "results sorted by score" );
