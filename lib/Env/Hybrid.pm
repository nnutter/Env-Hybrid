package Env::Hybrid;
use parent Exporter;

use 5.008005;
use strict;
use warnings;

use Carp qw(croak);
use Config qw(%Config);
use File::Spec qw();
use Memoize qw(memoize);

our $VERSION = "0.01";

sub relative_path { die 'must implement relative_path' }

# return a flat hashref
sub load_file { die 'must implement load_file' }

# a single base directory relative to which user-specific files should be read
sub env_config_home {
    return $ENV{XDG_CONFIG_HOME};
}

# a delimited list of preference ordered base directories relative to which
# files should be searched
sub env_config_dirs {
    return $ENV{XDG_CONFIG_DIRS};
}

# if you aren't directly subclassing Env::Hybrid
sub import_depth { 1 }

sub split {
    my $path_list = shift;
    CORE::split(/$Config{path_sep}/, $path_list, @_);
}

sub join {
    CORE::join($Config{path_sep}, @_);
}

sub dirs {
    my $class = shift;
    my @dirs;
    if ( $class->env_config_home ) {
        push @dirs, $class->env_config_home;;
    }
    if ( $class->env_config_dirs ) {
        push @dirs, Env::Hybrid::split($class->env_config_dirs);
    }
    return @dirs;
}

sub import {
    my $class = shift;
    my @vars  = @_;

    for my $var (@vars) {
        _validate_var_name($var);
    }

    my $config = $class->_load();

    for my $var (@vars) {
        my $varname = ($var =~ /\$(.*)/)[0];
        my $fullvarname = join('::', $class, $varname);
        if (defined $ENV{$varname}) {
            no strict 'refs';
            ${"$fullvarname"} = $ENV{$varname};
        } else {
            no strict 'refs';
            ${"$fullvarname"} = $config->{$varname};
        }
    }

    $class->export_to_level($class->import_depth, $class, @vars);
}

sub _validate_var_name {
    unless ($_[0] =~ /^\$[A-Za-z_]+$/) {
        croak 'invalid variable name: ' . $_[0];
    }
}


memoize('_load');
sub _load {
    my $class = shift;
    my @hashes = map {
        my $path = File::Spec->join($_, $class->relative_path);
        $class->load_file($path);
    } $class->dirs;
    my $merge = _merge(reverse @hashes);
    for my $key (keys %$merge) {
        if (ref $merge->{$key}) {
            croak 'expect flat config files';
        }
    }
    return $merge;
}

sub _merge {
    my @hashes = @_;
    my $merge = {};
    for my $hash (@hashes) {
        for my $key (keys %$hash) {
            $merge->{$key} = $hash->{$key};
        }
    }
    return $merge;
}

1;

__END__

=encoding utf-8

=head1 NAME

Env::Hybrid - It's new $module

=head1 SYNOPSIS

    use Env::Hybrid;

=head1 DESCRIPTION

Env::Hybrid is ...

=head1 LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nathaniel Nutter E<lt>iam@nnutter.comE<gt>

=cut

