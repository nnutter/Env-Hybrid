package Env::Hybrid::Test;
use parent Env::Hybrid;

package main;

use strict;
use warnings;

use Test::More tests => 2;

require Env::Hybrid;

my $count;

do {
    no warnings qw(once redefine);
    *Env::Hybrid::relative_path = sub { $count++ };
    *Env::Hybrid::_merge = sub { {} };
    *Env::Hybrid::load_file = sub { {} };
};

$count = 0;
Env::Hybrid::_load('Env::Hybrid');
Env::Hybrid::_load('Env::Hybrid');
is($count, 1, 'memoize works for _load');

$count = 0;
Env::Hybrid::Test->_load();
Env::Hybrid::Test->_load();
is($count, 1, 'memoize works for _load (subclass)');
