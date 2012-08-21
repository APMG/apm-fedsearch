package APM::FedSearch::View::TT;
use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    render_die => 1,

    # any TT configuration items go here
    TEMPLATE_EXTENSION => '.tt',
);

1;
