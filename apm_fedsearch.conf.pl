use strict;

{   name              => 'APM::FedSearch',
    'Controller::API' => { 'api_model' => 'API', },
    'Model::API'      => {
        urls => [
            'http://localhost:5000/search',
            'http://localhost:5001/search',
        ],
        fields =>
            [qw( uri title description author origin tags publish_date )],
        facets => [qw( author origin tags publish_date )],
    },

}
