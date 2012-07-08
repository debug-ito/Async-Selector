#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Async::Selector' ) || print "Bail out!\n";
}

diag( "Testing Async::Selector $Async::Selector::VERSION, Perl $], $^X" );
