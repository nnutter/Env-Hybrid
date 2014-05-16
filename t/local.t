use strict;
use warnings;

use File::Basename qw(dirname);
use lib File::Basename::dirname(__FILE__);

BEGIN {
    require Env::Hybrid::Test;
    Env::Hybrid::Test->init(
        ENV => {
            FOO => 'env',
        },
    );
    Env::Hybrid::Test->import(qw($FOO));
}

use Test::More tests => 6;

is($ENV{FOO}, 'env');
is($FOO, 'env');

do {
    local $FOO = 9999;
    is($ENV{FOO}, $FOO);
    is($FOO, 9999);
};

is($ENV{FOO}, 'env');
is($FOO, 'env');
