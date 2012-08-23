package APM::FedSearch::View::TT;
use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    render_die => 1,

    # any TT configuration items go here
    TEMPLATE_EXTENSION => '.tt',
);

1;

=head1 COPYRIGHT

Copyright 2012 - American Public Media Group

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
