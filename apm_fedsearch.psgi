use strict;
use warnings;
use lib 'lib';

use APM::FedSearch;

my $app
    = APM::FedSearch->apply_default_middlewares( APM::FedSearch->psgi_app );
$app;
