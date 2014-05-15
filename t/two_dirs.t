use strict;
use warnings;

package Env::Hybrid::YAML;
use parent 'Env::Hybrid';

use Config qw(%Config);
use File::Temp qw(tempdir);
use YAML::Syck qw(DumpFile LoadFile);

my $env_config_home;
BEGIN { $env_config_home = tempdir() }
sub env_config_home { $env_config_home };

my @env_config_dirs;
BEGIN { @env_config_dirs = (tempdir(), tempdir()) }
sub env_config_dirs { join($Config{path_sep}, @env_config_dirs) };

my $relative_path;
BEGIN { $relative_path = 'config.yaml' }
sub relative_path { $relative_path };

sub load_file {
    my ($class, $path) = @_;
    return LoadFile($path);
}

our (@EXPORT_OK, $env_config_home_data, @env_config_dirs_data);
BEGIN {
    my $i = 0;
    my $inc = sub { $i = $i + 10 };
    my @vars = qw(FOO);
    @EXPORT_OK = map { $_, '$' . $_ } @vars;
    $env_config_home_data = { };
    @env_config_dirs_data = (
        { $vars[0] => $inc->() },
        { $vars[0] => $inc->() },
    );
    DumpFile(File::Spec->join($env_config_home,    $relative_path), $env_config_home_data);
    DumpFile(File::Spec->join($env_config_dirs[0], $relative_path), $env_config_dirs_data[0]);
    DumpFile(File::Spec->join($env_config_dirs[1], $relative_path), $env_config_dirs_data[1]);
};

package main;

use Test::More tests => 7;

BEGIN {
    Env::Hybrid::YAML->import(qw(FOO $FOO));
}

ok  (!defined($ENV{FOO}));
isnt(FOO, $Env::Hybrid::YAML::env_config_home_data->{FOO});
is  (FOO, $Env::Hybrid::YAML::env_config_dirs_data[0]{FOO});
isnt(FOO, $Env::Hybrid::YAML::env_config_dirs_data[1]{FOO});
isnt($FOO, $Env::Hybrid::YAML::env_config_home_data->{FOO});
is  ($FOO, $Env::Hybrid::YAML::env_config_dirs_data[0]{FOO});
isnt($FOO, $Env::Hybrid::YAML::env_config_dirs_data[1]{FOO});
