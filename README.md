# NAME

Mojolicious::Plugin::Facets - Multiple facets for your app.

# SYNOPSIS

    package MyApp;

    use Mojo::Base 'Mojolicious';
    use FindBin;



    sub startup {
        my $app = shift;

        # set default static/renderer paths, routes and namespaces

        $app->plugin('Facets',
            backoffice => {
                host   => 'backoffice.example.com',
                setup  => \&_setup_backoffice
            }
        );
    }

    sub _setup_backoffice {
        my $app = shift;

        # set default static/renderer paths, routes and namespaces
        @{$app->static->paths} = ($app->home->child('backoffice/static')->to_string);
        @{$app->renderer->paths} = ($app->home->child('backoffice/template')->to_string);
        @{$app->routes->namespaces} = ('MyApp::Backoffice');

        my $r = $app->routes;
        @{$r->namespaces} = ('MyApp::Backoffice');
    }

# DESCRIPTION

Mojolicious::Plugin::Facets allows you to declare multiple facets on a Mojolicious app.
A Facet is a way to organize you app as if it were multiple apps. Each facet can
declare its own routes, namespaces, static paths and renderer paths.

A common use case is to create a facet for the backoffice application.

# LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Carlos Fernando Avila Gratz <cafe@kreato.com.br>
