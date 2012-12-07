use strict;
use warnings;
use Test::More;
use Test::Warn;

BEGIN {
    use_ok('Async::Selector');
    use_ok('Async::Selector::Selection'); ## -> Watcher
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
    isa_ok($w, 'Async::Selector::Selection');
    ok($w->active, "watcher is active");
    is(int($s->watchers), 1, "1 pending watcher");
    is(int(@result), 0, "result empty");
    $res = 10;
    $s->trigger('a');
    ok(!$w->active, "watcher is now inactive");
    is(int($s->watchers), 0, "0 pending watcher");
    is(int(@result), 1, "1 result...");
    is($result[0], 10, '... and it is 10');

    note('--- -- empty watch');
    $w = $s->watch(sub {
        fail('This should not be executed.');
    });
    isa_ok($w, "Async::Selector::Selection");
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
    note('--- $selector->cancel($watcher)');
    note('    This form is supported for backward compatibility. $watcher->cancel() is favored.');

    my $s = Async::Selector->new();
    my $res = 0;
    $s->register(a => sub {
        my $in = shift;
        return $res >= $in ? $res : undef;
    });

    note("--- -- LT select, non-remove, not immediate.");
    my $w = $s->watch(a => 10, sub {
        my ($r, %res) = @_;
        fail("This should not be executed.");
        return 0;
    });
    isa_ok($w, 'Async::Selector::Selection');
    is(int($s->watchers), 1, "1 watcher.");
    is($s->cancel($w), $s, "cancel() returns Selector object.");
    is(int($s->watchers), 0, "0 watcher.");

    note("--- -- LT select, non-remove, immediate.");
    my @result = ();
    $w = $s->watch(a => -10, sub {
        my ($r, %res) = @_;
        push(@result, $res{a});
        return 0;
    });
    isa_ok($w, 'Async::Selector::Selection');
    is(int(@result), 1, "Immediate watch.");
    is($result[0], 0, "The result is obtained.");
    $s->cancel($w);
    is(int($s->watchers), 0, "No pending watcher");
    @result = ();
    $s->trigger('a');
    $s->trigger('a');
    is(int(@result), 0, "No result obtained because no pending watcher.");

    note("--- -- N-resources, 1-selection cancel.");
    $s = Async::Selector->new();
    foreach my $res_id (1 .. 5) {
        $s->register($res_id => sub {
            my $in = shift;
            return $res_id >= $in ? $res_id : undef;
        });
    }
    $w = $s->watch(1 => 5, 2 => 6, 5 => 7, sub {
        my ($r, %res) = @_;
        fail("This should not be executed.");
    });
    isa_ok($w, 'Async::Selector::Selection');
    is(int($s->watchers), 1, "1 pending watchers.");
    $s->cancel($w);
    is(int($s->watchers), 0, "0 pending watchers.");

    note('--- -- 1-resource,  M-selections cancel.');
    $s = Async::Selector->new();
    $s->register(a => sub { undef });
    my @ws = ();
    foreach my $threshold (1 .. 10) {
        push(@ws, $s->watch(a => $threshold, sub {
            fail('This should not be executed.');
        }));
    }
    is(int($s->watchers), 10, "10 pending watchers");
    $s->cancel(@ws[2,4,5,8]);
    is(int($s->watchers), 6, "6 pending watchers");
    $s->cancel($s->watchers);
    is(int($s->watchers), 0, "0 pending watchers");
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

{
    note('--- $selector->cancel($request_in_other_selector)');
    my $sa = Async::Selector->new();
    my $sb = Async::Selector->new();
    my $wa = $sa->watch(a => 10, sub {
        fail('This should not be executed.');
    });
    isa_ok($wa, 'Async::Selector::Selection');
    my $wb = $sb->watch(b => 10, sub {
        fail('This should not be executed.');
    });
    isa_ok($wb, 'Async::Selector::Selection');
    is(int($sa->watchers), 1, '1 watcher in $sa');
    is(int($sb->watchers), 1, '1 watcher in $sb');
    ok($wa->active, '$wa is active');
    ok($wb->active, '$wb is active');
    warning_is { $sa->cancel($wb) } undef, 'No warning';
    warning_is { $sb->cancel($wa) } undef, 'No warning';
    is(int($sa->watchers), 1, 'Still 1 watcher in $sa');
    is(int($sb->watchers), 1, 'Still 1 watcher in $sb');
    ok($wa->active, '$wa is still active');
    ok($wb->active, '$wb is still active');
    $sa->cancel($wa);
    $sb->cancel($wb);
    is(int($sa->watchers), 0, '0 watcher in $sa');
    is(int($sb->watchers), 0, '0 watcher in $sb');
    ok(!$wa->active, '$wa is inactive');
    ok(!$wb->active, '$wb is inactive');
}


done_testing();



