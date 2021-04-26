#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use Mojolicious::Commands;
use Mojolicious::Plugins;
 
my $plugins = Mojolicious::Plugins->new;
push @{$plugins->namespaces}, 'App::Plugins';


# Start command line interface for application
Mojolicious::Commands->start_app('App');
