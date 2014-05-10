use strict;
use warnings;

use Test::More tests => 3;

require Env::Hybrid;

my $a = {
    a => 1,
    d => 'a',
};
my $b = {
    b => 3,
    d => 'b',
};
my $c = {
    c => 5,
    d => 'c',
};

do {
    my $merge = Env::Hybrid::_merge($a, $b, $c);
    my $expected = { a => $a->{a}, b => $b->{b}, c => $c->{c}, d => $c->{d} };
    is_deeply($merge, $expected);
};

do {
    my $merge = Env::Hybrid::_merge($b, $c, $a);
    my $expected = { a => $a->{a}, b => $b->{b}, c => $c->{c}, d => $a->{d} };
    is_deeply($merge, $expected);
};

do {
    my $merge = Env::Hybrid::_merge($c, $a, $b);
    my $expected = { a => $a->{a}, b => $b->{b}, c => $c->{c}, d => $b->{d} };
    is_deeply($merge, $expected);
};
