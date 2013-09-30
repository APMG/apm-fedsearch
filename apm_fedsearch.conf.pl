use strict;

{   name              => 'APM::FedSearch',
    'Controller::API' => { 'api_model' => 'API', },
    'Model::API'      => {
        urls => [
            'http://localhost:5000/mpr/search',
            'http://localhost:5000/tpt/search',
            'http://localhost:5000/spco/search',

            # TODO other urls
        ],
        base_uri => 'http://www.mnculture.org/api/',
        fields =>
            [qw( uri title description author origin tags publish_date guid )],
        facets => [qw( author origin tags )],
    },

}
