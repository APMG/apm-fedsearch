use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";

use APM::FedSearch;

my $app
    = APM::FedSearch->apply_default_middlewares( APM::FedSearch->psgi_app );
$app;
