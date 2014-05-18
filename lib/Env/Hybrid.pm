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

sub load_file { die 'must implement load_file()' }

sub validate { 1 }

sub env_config_home {
    return $ENV{XDG_CONFIG_HOME} || File::Spec->join($ENV{HOME}, '.config');
}

sub env_config_dirs {
    return $ENV{XDG_CONFIG_DIRS} || '/etc/xdg';
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
            _define_read_write($class, $varname);
        } else {
            _define_read_only($class, $varname);
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

sub _define_read_write {
    my ($package, $name) = @_;
    my $fqname = join('::', $package, $name);
    no strict 'refs';
    tie ${"$fqname"}, __PACKAGE__, $package, $name;
}

sub _define_read_only {
    my ($package, $name) = @_;
    my $fqname = join('::', $package, $name);
    no strict 'refs';
    *{"$fqname"} = sub {
        if (@_) {
            die "$fqname is read-only";
        }
        my $config = $package->_load();
        my $value = defined($ENV{$name}) ? $ENV{$name} : $config->{$name};
        $package->validate($name, $value);
        return $value;
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
    my $class = ref $self;
    my $config = $class->_load();
    my $name = $$self;
    my $value = defined($ENV{$name}) ? $ENV{$name} : $config->{$name};
    $class->validate($name, $value);
    return $value;
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

Env::Hybrid - Use environment variables and configuration files.

=head1 DESCRIPTION

Env::Hybrid is an abstract class that should be used to implement a
configuration singleton for your app.

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

