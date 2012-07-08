
use strict;
use warnings;
use Test::More;

note("Test for 1-resource 1-selection.");

BEGIN {
    use_ok('Async::Selector');
}


my $s = new_ok('Async::Selector');
cmp_ok(int($s->resources), '==', 0, 'zero resources registered.');

my $res_a = 0;
is($s->register(
    "a", sub {
        my $in = shift;
        return $res_a >= $in ? $res_a : undef;
    }
), $s, 'register() returns the object.');

cmp_ok(int($s->resources), "==", 1, "one resource registered.");
is(($s->resources)[0], 'a', '... and its name is "a".');

note("--- LT select, auto-remove, not immediate.");
my @result = ();
ok(defined($s->select(
    sub {
        my ($id, %res) = @_;
        cmp_ok(int(keys %res), "==", 1, "selected one resource.");
        ok(defined($res{a}), "resource a is available.");
        push(@result, $res{a});
        return 1;
    }, a => 5)), "select() returns some value if the request is pending."
);


foreach (0 .. 4) {
    is($s->trigger('a'), $s, 'trigger() method returns the object.');
    cmp_ok(int(@result), "==", 0, 'no entry in result yet.');
    $res_a++;
}
cmp_ok($res_a, '==', 5, "now res_a is 5.");
$s->trigger('a');
cmp_ok(int(@result), '==', 1, 'one result has arrived!');
cmp_ok((shift @result), '==', $res_a, "... and it's $res_a.");

$s->trigger('a');
cmp_ok(int(@result), "==", 0, "no result anymore, because the selection was removed.");

note("--- LT select, auto-remove, immediate fire.");
ok(!defined($s->select(
    sub {
        my ($id, %res) = @_;
        push(@result, $res{a});
        return 1;
    }, a => 3)), "select() returns undef if the request is handled immediately."
);
cmp_ok(int(@result), "==", 1, "get a result without trigger()");
is((shift @result), $res_a, "... and it's $res_a");

{
    note("--- LT select, non-remove, not immediate.");
    @result = ();
    my $id = $s->select(
        sub {
            my ($id, %res) = @_;
            push(@result, $res{a});
            return 0;
        }, a => 10
    );
    ok(defined($id), "select() method returns defined ID");
    $res_a = 9; $s->trigger('a');
    cmp_ok(int(@result), "==", 0, "no result.");
    $res_a = 10; $s->trigger('a');
    cmp_ok(int(@result), "==", 1, "got a result.");
    is((shift @result), $res_a, "... and is $res_a");
    $s->trigger('a') foreach 1..3;
    cmp_ok(int(@result), "==", 3, "every call to trigger() kicks the selection callback repeatedly.");
    is($_, $res_a, "... the result is $res_a") foreach @result;
    @result = ();
    
    note("--- -- cancel() operation.");
    is($s->cancel($id), $s, "cancel() returns the object.");
    $s->trigger('a') foreach 1..3;
    cmp_ok(int(@result), "==", 0, "no result because the selection is canceled.");
}

note("--- LT select, non-remove, immediate.");
note("--- -- cancel() operation.");

note("--- ET select, auto-remove, not immediate / immediate.");

note("--- register() to update the provider.");

note("--- unregister()");
is($s->unregister('a'), $s, "unregister() returns the object.");
cmp_ok(int($s->resources), '==', 0, "now no resource is registered.");

done_testing();






