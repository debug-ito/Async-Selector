use Test::More tests => 2;

BEGIN {
    use_ok('Async::Selector' );
    use_ok('Async::Selector::Selection');
}

diag( "Testing Async::Selector $Async::Selector::VERSION, Perl $], $^X" );
