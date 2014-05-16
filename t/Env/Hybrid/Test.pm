package Env::Hybrid::Test;
use parent 'Env::Hybrid';

use strict;
use warnings;

use Config qw(%Config);
use File::Spec qw();
use File::Temp qw(tempdir);
use List::MoreUtils qw(uniq);
use YAML::Syck qw(DumpFile LoadFile);

my @vars;
sub vars { @vars }
sub relative_path { 'config.yaml' }
sub load_file { shift; LoadFile(shift) }

sub init {
    my $class = shift;
    my $test_data = { @_ };

    my @ivars;

    for my $k (keys %{$test_data->{ENV}}) {
        push @ivars, $k;
        $ENV{$k} = $test_data->{ENV}{$k};
    }


    my @data;
    if (exists $test_data->{HOME}) {
        push @data, $test_data->{HOME};
    }
    if (exists $test_data->{DIRS}) {
        push @data, @{$test_data->{DIRS}};
    }

    my @dirs = map { tempdir() } @data;
    for (my $i = 0; $i < @data; $i++) {
        my $tempfilename = File::Spec->join($dirs[$i], relative_path());
        push @ivars, keys %{$data[$i]};
        DumpFile($tempfilename, $data[$i]);
    }

    if (exists $test_data->{HOME}) {
        $ENV{XDG_CONFIG_HOME} = shift @dirs;
    }
    if (exists $test_data->{DIRS}) {
        $ENV{XDG_CONFIG_DIRS} = join($Config{path_sep}, @dirs);
    }

    @vars = uniq @ivars;
}

1;
