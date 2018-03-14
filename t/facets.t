use strict;
use Test::More 0.98;
use Test::Mojo;
# use Data::Printer;

my $t = Test::Mojo->new('TestApp');


subtest 'routes' => sub {
    $t->get_ok('/')->content_is('default root');

    $t->get_ok('/' => {'Host' => 'backoffice' })
      ->content_is('backoffice root');

    $t->get_ok('/')->content_is('default root');
};


subtest 'static paths' => sub {

    $t->get_ok('/file.txt')->content_like(qr/default/);
    $t->get_ok('/file.txt' => {'Host' => 'backoffice' })->content_like(qr/backoffice/);
    $t->get_ok('/file.txt')->content_like(qr/default/);
    # $t->get_ok('/file.txt')->content_is('default static');
};


subtest 'renderer paths' => sub {

    $t->get_ok('/page')->content_like(qr/default page/);

    $t->get_ok('/backoffice-page' => {'Host' => 'backoffice' })
      ->status_is(200)
      ->content_like(qr/backoffice page/);


    $t->get_ok('/backoffice-page')->status_is(404);
    $t->get_ok('/page' => {'Host' => 'backoffice' })->status_is(404);

    $t->get_ok('/page')->content_like(qr/default page/);
};


subtest 'controller namespaces' => sub {

    $t->get_ok('/controller')->status_is(200)->content_like(qr/default controller/);
    $t->get_ok('/controller' => {'Host' => 'backoffice' })->status_is(200)->content_like(qr/backoffice controller/);
    # $t->get_ok('/controller')->content_like(qr/default controller/);
};


subtest 'sessions' => sub {
    $t->ua->max_redirects(1);

    $t->get_ok('/session')
      ->status_is(200)->json_is('/facet', 'none')->json_is('/cookie', 'mojolicious');

    $t->get_ok('/session' => {'Host' => 'backoffice' })->status_is(200);
    $t->get_ok('/dump-session' => {'Host' => 'backoffice' })
      ->status_is(200)->json_is('/facet', 'backoffice')->json_is('/cookie', 'backoffice');
};




done_testing;


{
    package TestApp;

    use Mojo::Base 'Mojolicious';
    use FindBin;

    sub startup {
        my $app = shift;

        $app->home(Mojo::Home->new("$FindBin::Bin/app_home"));
        @{$app->static->paths} = ($app->home->child('public')->to_string);
        @{$app->renderer->paths} = ($app->home->child('template')->to_string);

        $app->plugin('Facets',
            backoffice => {
                host   => 'backoffice',
                setup  => \&_setup_backoffice
            }
        );

        $app->routes->get('/' => { text => 'default root' });
        $app->routes->get('/page' => { template => 'page' });
        $app->routes->get('/controller')->to('foo#process');
        $app->routes->get('/session' => sub {
            my $c = shift;
            $c->session->{facet} = 'none';
            $c->session->{cookie} = $c->app->sessions->cookie_name;
            $c->redirect_to('/dump-session');
        });
        $app->routes->get('/dump-session' => sub {
            my $c = shift;
            $c->render(json => $c->session);
        });

    }

    sub _setup_backoffice {
        my $app = shift;

        @{$app->static->paths} = ($app->home->child('backoffice/static')->to_string);
        @{$app->renderer->paths} = ($app->home->child('backoffice/template')->to_string);
        @{$app->routes->namespaces} = ('TestApp::Backoffice');

        $app->sessions->cookie_name('backoffice');

        my $r = $app->routes;
        $r->get('/' => { text => 'backoffice root' });
        $r->get('/backoffice-page' => { template => 'page' });
        $app->routes->get('/controller')->to('foo#process');

        $app->routes->get('/session' => sub {
            my $c = shift;
            $c->session->{facet} = 'backoffice';
            $c->session->{cookie} = $c->app->sessions->cookie_name;
            $c->rendered(200);
        });

        $app->routes->get('/dump-session' => sub {
            my $c = shift;
            $c->render(json => $c->session);
        });
    }

    package TestApp::Foo;
    use Mojo::Base 'Mojolicious::Controller';

    sub process {
        shift->render(text => 'default controller')
    }

    package TestApp::Backoffice::Foo;
    use Mojo::Base 'Mojolicious::Controller';

    sub process {
        shift->render(text => 'backoffice controller')
    }

}
