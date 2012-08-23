#!/usr/bin/env perl
# IMPORTANT: if you delete this file your app will not work as
# expected.  You have been warned.
use inc::Module::Install 1.02;
use Module::Install::Catalyst; # Complain loudly if you don't have
                               # Catalyst::Devel installed or haven't said
                               # 'make dist' to create a standalone tarball.

name 'APM-FedSearch';
all_from 'lib/APM/FedSearch.pm';

requires 'Search::OpenSearch' => '0.20';
requires 'Data::Transformer'  => 0;
requires 'JSON' => '2.0';
requires 'Parallel::Iterator' => 0;
requires 'XML::Simple' => 0;
requires 'XML::Feed' => 0;
requires 'LWP::UserAgent' => 0;
requires 'Catalyst::View::TT' => 0;
requires 'Catalyst::Runtime' => '5.90016';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Moose';
requires 'namespace::autoclean';
requires 'Config::General'; # This should reflect the config file format you've chosen
                 # See Catalyst::Plugin::ConfigLoader for supported formats
test_requires 'Test::More' => '0.88';
catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
