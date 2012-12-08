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
$s->watch(a => undef, b => undef, c => undef, sub {
    my ($w, %res) = @_;
    $fired = 1;
    ok(!defined($res{a}), 'a is not ready');
    is($res{b}, "B", 'b is ready');
    ok(!defined($res{c}), 'c is not ready');
    $w->cancel();
});
is($fired, 1, 'watcher fired immediately');
is(int($s->watchers), 0, "no watcher");

$fired = 0;
$s->watch_et(a => undef, b => undef, c => undef, sub {
    my ($w, %res) = @_;
    $fired = 1;
    ok(!defined($res{a}), 'a is not ready');
    is($res{b}, "B", 'b is ready');
    ok(!defined($res{c}), 'c is not ready');
    $w->cancel();
});
is($fired, 0, 'watcher not fired because its ET');
$s->trigger(qw(a b c));
is($fired, 1, "watcher fired");
is(int($s->watchers), 0, "no watcher");


$fired = 0;
$s->watch(a => '', b => 0, c => '', sub {
    my ($w, %res) = @_;
    $fired = 1;
    is($res{a}, "A", 'a is ready');
    ok(!defined($res{b}), 'b is not ready');
    is($res{c}, "C", 'c is ready');
    $w->cancel();
});
is($fired, 1, 'watcher fired immediately');
is(int($s->watchers), 0, "no watcher");

$fired = 0;
$s->watcher_et(a => '', b => 0, c => '', sub {
    my ($w, %res) = @_;
    $fired = 1;
    is($res{a}, "A", 'a is ready');
    ok(!defined($res{b}), 'b is not ready');
    is($res{c}, "C", 'c is ready');
    $w->cancel();
});
is($fired, 0, 'watcher not fired because its ET');
$s->trigger(qw(a b c));
is($fired, 1, 'watcher fired');
is(int($s->watchers), 0, "no watcher");

done_testing();
