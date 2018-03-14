package Mojolicious::Plugin::Facets;

use Mojo::Base 'Mojolicious::Plugin';
use Mojolicious::Routes;
use Mojolicious::Static;
use Mojo::Cache;
# use Data::Printer;

our $VERSION = "0.01";

my @facets;

sub register {
    my ($self, $app, $config) = @_;

    my @default_static_paths = @{ $app->static->paths };
    my @default_renderer_paths = @{ $app->renderer->paths };
    my @default_routes_namespaces = @{ $app->routes->namespaces };

    foreach my $facet_name (keys %$config) {

        my $facet_config = $config->{$facet_name};
        die "Missing 'setup' key on facet '$facet_name' config." unless $facet_config->{setup};
        die "Missing 'host' key on facet '$facet_name' config." unless $facet_config->{host};

        my $facet = {
            name => $facet_name,
            host => $facet_config->{host},
            routes => Mojolicious::Routes->new(namespaces => [@default_routes_namespaces]),
            static => Mojolicious::Static->new,
            renderer_paths => [@default_renderer_paths],
            renderer_cache => Mojo::Cache->new
        };

        local $app->{routes} = $facet->{routes};
        local $app->{static} = $facet->{static};
        local $app->renderer->{paths} = $facet->{renderer_paths};
        local $app->renderer->{cache} = $facet->{renderer_cache};
        $facet_config->{setup}->($app);

        push @facets, $facet;
    }

    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;

        # detect facet
        my $active_facet;
        my $req_host = $c->req->headers->host;
        $req_host =~ s/:\d+$//;
        foreach my $facet (@facets) {

            if ($req_host eq $facet->{host}) {
                $active_facet = $facet;
                last
            }
        }

        # localize relevand data and continue dispatch chain
        if ($active_facet) {
            $c->app->log->debug(qq/Dispatching facet "$active_facet->{name}"/);

            local $c->app->{routes} = $active_facet->{routes};
            local $c->app->{static} = $active_facet->{static};
            local $c->app->renderer->{paths} = $active_facet->{renderer_paths};
            local $c->app->renderer->{cache} = $active_facet->{renderer_cache};
            $next->();
        }
        else {
            # no facet, continue dispatch
            $next->();
        }

    });
}






1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::Facets - Multiple facets for your app.

=head1 SYNOPSIS

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


=head1 DESCRIPTION

Mojolicious::Plugin::Facets allows you to declare multiple facets on a Mojolicious app.
A Facet is a way to organize you app as if it were multiple apps. Each facet can
declare its own routes, namespaces, static paths and renderer paths.

A common use case is to create a facet for the backoffice application.

=head1 LICENSE

Copyright (C) Carlos Fernando Avila Gratz.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Carlos Fernando Avila Gratz E<lt>cafe@kreato.com.brE<gt>

=cut
