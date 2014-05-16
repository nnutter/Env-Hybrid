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

sub vars { die 'must implement vars()' }

sub relative_path { die 'must implement relative_path()' }

# return a flat hashref
sub load_file { die 'must implement load_file()' }

# a single base directory relative to which user-specific files should be read
sub env_config_home {
    return $ENV{XDG_CONFIG_HOME};
}

# a delimited list of preference ordered base directories relative to which
# files should be searched
sub env_config_dirs {
    return $ENV{XDG_CONFIG_DIRS};
}

sub split_path {
    my $path_list = shift;
    split(/$Config{path_sep}/, $path_list, @_);
}

sub join_path {
    join($Config{path_sep}, @_);
}

sub dirs {
    my $class = shift;
    my @dirs;
    if ( $class->env_config_home ) {
        push @dirs, $class->env_config_home;;
    }
    if ( $class->env_config_dirs ) {
        push @dirs, split_path($class->env_config_dirs);
    }
    return @dirs;
}

sub import {
    my $class = shift;
    my @vars  = @_;

    _set_export_ok($class);

    for my $var (@vars) {
        my ($sigil, $varname) = ($var =~ /^(\$?)(.*)$/);
        _validate_var_name($varname);
        if ($sigil) {
            _define_scalar($class, $varname);
        } else {
            _define_constant($class, $varname);
        }
    }

    $class->export_to_level(1, $class, @vars);
}

sub _set_export_ok {
    my ($package) = @_;
    my $fqname = join('::', $package, 'EXPORT_OK');
    no strict 'refs';
    @{"$fqname"} = map { $_, '$' . $_ } $package->vars();
}

sub _define_scalar {
    my ($package, $name) = @_;
    my $fqname = join('::', $package, $name);
    no strict 'refs';
    tie ${"$fqname"}, __PACKAGE__, $package, $name;
}

sub _define_constant {
    my ($package, $name) = @_;
    my $fqname = join('::', $package, $name);
    no strict 'refs';
    *{"$fqname"} = sub {
        my $config = $package->_load();
        my $value = defined($ENV{$name}) ? $ENV{$name} : $config->{$name};
    };
}

sub _validate_var_name {
    unless ($_[0] =~ /^[A-Za-z_]+$/) {
        croak 'invalid import name: ' . $_[0];
    }
}

memoize('_load');
sub _load {
    my $class = shift;

    my @hashes;
    for my $dir ($class->dirs) {
        my $path = File::Spec->join($dir, $class->relative_path);
        next unless -f $path;
        push @hashes, $class->load_file($path);
    }
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

sub TIESCALAR {
    my ($class, $package, $name) = @_;
    bless \$name, $package;
}

sub FETCH {
    my ($self) = @_;
    my $config = $self->_load();
    my $value = defined($ENV{$$self}) ? $ENV{$$self} : $config->{$$self};
}

sub STORE {
    my ($self, $value) = @_;
    if (defined($value)) {
        $ENV{$$self} = $value;
    } else {
        delete $ENV{$$self};
    }
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

=head1 EXAMPLE

Here's an example where variables would be defined as packages under MyApp::Env:

    package MyApp::Env;
    use parent 'Env::Hybrid';

    use Module::Find qw(findsubmod);
    use YAML::Syck qw(LoadFile);

    sub vars {
        my $package = __PACKAGE__;
        my @var_packages = findsubmod 'MyApp::Env';
        return map { [$_ =~ /^$package\::(.*)$/]->[0] } @var_packages;
    }

    sub relative_path { 'myapp/config.yaml' }
    sub load_file { shift; LoadFile(shift) }

Elsewhere the variables could then be imported:

    use MyApp::Env qw(MYAPP_LOGIN MYAPP_PASSWORD);

=head1 LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nathaniel Nutter E<lt>nnutter@cpan.orgE<gt>

=cut

