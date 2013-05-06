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
        fields =>
            [qw( uri title description author origin tags publish_date )],
        facets => [qw( author origin tags )],
    },

}
