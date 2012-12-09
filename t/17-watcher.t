use strict;
use warnings;
use Test::More;
use Test::Warn;

BEGIN {
    use_ok('Async::Selector');
    use_ok('Async::Selector::Watcher');
}

{
    note('--- active() method.');
    my $s = Async::Selector->new();
    my $res = 0;
    $s->register(a => sub {
        my $in = shift;
        return $res >= $in ? $res : undef;
    });
    my @result = ();
    my $w = $s->watch(a => 10, sub {
        my ($w, %res) = @_;
        push(@result, $res{a});
        $w->cancel();
    });
    isa_ok($w, 'Async::Selector::Watcher');
    ok($w->active, "watcher is active");
    is(int($s->watchers), 1, "1 pending watcher");
    is(int(@result), 0, "result empty");
    $res = 10;
    $s->trigger('a');
    ok(!$w->active, "watcher is now inactive");
    is(int($s->watchers), 0, "0 pending watcher");
    is(int(@result), 1, "1 result...");
    is($result[0], 10, '... and it is 10');

    note('--- -- immediate');
    @result = ();
    $w = $s->watch(a => 5, sub {
        my ($w, %res) = @_;
        push(@result, $res{a});
        $w->cancel();
    });
    is($result[0], 10, 'immediate fire');
    is(int($s->watchers), 0, 'no watcher');
    isa_ok($w, 'Async::Selector::Watcher', 'even in the immediate fire case, watch() should return a Watcher');
    ok(!$w->active, '... and it is inactive.');

    note('--- -- empty watch');
    $w = $s->watch(sub {
        fail('This should not be executed.');
    });
    isa_ok($w, "Async::Selector::Watcher");
    ok(!$w->active, 'empty watch should return an inactive watcher.');
}

sub checkConditions {
    my ($s, $watch_args, $exp_res, $exp_cond, $case) = @_;
    my $w = $s->watch(@$watch_args);
    is_deeply([sort {$a cmp $b} $w->resources], $exp_res, $case . ': resources()');
    is_deeply({$w->condition}, $exp_cond, $case . ': condition()');
}

{
    note('--- condition() and resources() methods.');
    my $s = Async::Selector->new();
    my $failcb = sub { fail('This should not be executed.') };
    checkConditions($s, [a => 10, $failcb], ['a'], {a => 10}, "watch 1 resource");
    my $cond_array = [qw(x y z)];
    checkConditions(
        $s, [b => 'foobar', c => 992.5, a => $cond_array, $failcb],
        [qw(a b c)], { a => $cond_array, b => 'foobar', c => 992.5 },
        'watch 3 resources'
    );
    checkConditions($s, [$failcb], [], {}, "empty watch")
}

{
    note('--- call() method.');
    my $s = Async::Selector->new();
    my @result = ();
    my $w; $w = $s->watch(sub {
        my ($warg, @args) = @_;
        is($warg, $w, '$warg is $w itself');
        push(@result, @args);
    });
    is(int(@result), 0, 'result empty');
    $w->call(1, 2, 3, 4);
    is_deeply(\@result, [1, 2, 3, 4], 'result filled.');
}

{
    note('--- cancel() multiple times on the same Watcher.');
    my $s = Async::Selector->new();
    my $w = $s->watch(a => 10, sub {
        fail("This should not be executed.");
    });
    is(int($s->watchers), 1, '1 pending watcher.');
    $s->trigger('a');
    $s->trigger('a');
    is(int($s->watchers), 1, '1 pending watcher.');
    $w->cancel();
    is(int($s->watchers), 0, '0 pending watcher.');
    warning_is { $w->cancel() } undef, 'calling cancel() multiple times is ok.';
}

done_testing();



