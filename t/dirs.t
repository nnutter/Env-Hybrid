package Env::Hybrid::Test;
use parent Env::Hybrid;

package main;

use strict;
use warnings;

use Test::More tests => 3;

use Config qw(%Config);
require Env::Hybrid;


do {
    my @expected = qw(HOME DIR1 DIR2);
    no warnings qw(once redefine);
    *Env::Hybrid::Test::env_config_home = sub { $expected[0] };
    *Env::Hybrid::Test::env_config_dirs = sub {
        join($Config{path_sep}, @expected[1, 2])
    };
    is_deeply([Env::Hybrid::Test->dirs], \@expected);
};


do {
    my @expected = qw(DIR1 DIR2);
    no warnings qw(once redefine);
    *Env::Hybrid::Test::env_config_home = sub { };
    *Env::Hybrid::Test::env_config_dirs = sub {
        join($Config{path_sep}, @expected)
    };
    is_deeply([Env::Hybrid::Test->dirs], \@expected);
};

do {
    my $expected = 'HOME';
    no warnings qw(once redefine);
    *Env::Hybrid::Test::env_config_home = sub { $expected };
    *Env::Hybrid::Test::env_config_dirs = sub { };
    is_deeply([Env::Hybrid::Test->dirs], [$expected]);
};
