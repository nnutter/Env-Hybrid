use strict;
use warnings;

use File::Basename qw(dirname);
use lib File::Basename::dirname(__FILE__);

BEGIN {
    require Env::Hybrid::Test;
    Env::Hybrid::Test->init(
        DIRS => [
            { FOO => 'upper' },
            { FOO => 'lower' },
        ],
    );
    Env::Hybrid::Test->import(qw(FOO $FOO));
}

use Test::More tests => 3;

ok  (!defined($ENV{FOO}));
is  (FOO, 'upper');
is  ($FOO, 'upper');
