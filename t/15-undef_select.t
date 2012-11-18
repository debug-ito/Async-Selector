use strict;
use warnings;
use Test::More;
use Test::Warn;

BEGIN {
    use_ok('Async::Selector');
}

my $s = new_ok('Async::Selector');

$s->register(
    a => sub { my $in = shift;  return defined($in) ? 'A' : undef },
    b => sub { my $in = shift;  return defined($in) ? undef : 'B' },
    c => sub { my $in = shift;  return defined($in) ? 'C' : undef },
);

my $fired = 0;
$s->select(a => undef, b => undef, c => undef, sub {
    my ($id, %res) = @_;
    $fired = 1;
    ok(!defined($res{a}), 'a is not ready');
    is($res{b}, "B", 'b is ready');
    ok(!defined($res{c}), 'c is not ready');
    return 1;
});
is($fired, 1, 'selection fired immediately');
is(int($s->selections), 0, "no selection");

$fired = 0;
$s->select_et(a => undef, b => undef, c => undef, sub {
    my ($id, %res) = @_;
    $fired = 1;
    ok(!defined($res{a}), 'a is not ready');
    is($res{b}, "B", 'b is ready');
    ok(!defined($res{c}), 'c is not ready');
    return 1;
});
is($fired, 0, 'selection not fired because its ET');
$s->trigger(qw(a b c));
is($fired, 1, "selection fired");
is(int($s->selections), 0, "no selection");


$fired = 0;
$s->select(a => '', b => 0, c => '', sub {
    my ($id, %res) = @_;
    $fired = 1;
    is($res{a}, "A", 'a is ready');
    ok(!defined($res{b}), 'b is not ready');
    is($res{c}, "C", 'c is ready');
    return 1;
});
is($fired, 1, 'selection fired immediately');
is(int($s->selections), 0, "no selection");

$fired = 0;
$s->select_et(a => '', b => 0, c => '', sub {
    my ($id, %res) = @_;
    $fired = 1;
    is($res{a}, "A", 'a is ready');
    ok(!defined($res{b}), 'b is not ready');
    is($res{c}, "C", 'c is ready');
    return 1;
});
is($fired, 0, 'selection not fired because its ET');
$s->trigger(qw(a b c));
is($fired, 1, 'selection fired');
is(int($s->selections), 0, "no selection");




done_testing();





