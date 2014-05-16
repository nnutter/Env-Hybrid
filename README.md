[![Build Status](https://travis-ci.org/nnutter/Env-Hybrid.png?branch=master)](https://travis-ci.org/nnutter/Env-Hybrid)
# NAME

Env::Hybrid - It's new $module

# SYNOPSIS

    use Env::Hybrid;

# DESCRIPTION

Env::Hybrid is ...

# EXAMPLE

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

# LICENSE

Copyright (C) Nathaniel Nutter.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Nathaniel Nutter <nnutter@cpan.org>
