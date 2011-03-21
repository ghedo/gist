#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'App::gist' ) || print "Bail out!
";
}

diag( "Testing App::gist $App::gist::VERSION, Perl $], $^X" );
