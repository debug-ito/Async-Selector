use strict;
use warnings;
use Test::More;
use Test::Warn;
use Test::Exception;
use Async::Selector;

note('Test for erroneous situations.');

sub catter {
    my ($result_ref, $ret_val) = @_;
    return sub {
        my ($id, %res) = @_;
        $$result_ref .= join ',', map { "$_:$res{$_}" } sort {$a cmp $b} grep { defined($res{$_}) } keys %res;
        return $ret_val;
    };
}

{
    note('--- select() non-existent resource');
    my $s = new_ok('Async::Selector');
    $s->register("res" => sub { my $in = shift; return $in ? "RES" : undef });
    my $result = "";
    warning_is { $s->select(catter(\$result, 1), unknown => 100) } undef, "No warning for selecting non-existent resource.";
    warning_is { $s->select(sub { return 1 }, res => 1, unknown => 20) } undef, "... neither when existent resource is selected as well.";
    $s->register("unknown" => sub { return 10 });
    is($result, "", "The result is empty");
    $s->trigger("unknown");
    is($result, "unknown:10", "The result is now 'token' because the resource 'unknown' now exists and be triggered.");
}

{
    note('--- select() undef resource');
    my $s = new_ok('Async::Selector');
    my $result = "";
    warning_like {$s->select(catter(\$result, 1), undef, 100, res => 200)}
        qr/uninitialized/i, "Selecting undef is treated as selecting a resource named empty string.";
    $s->register(res => sub { return "RES" }, "" => sub { return "EMPTY" });
    is($result, "", "result is empty before trigger");
    $result = "";
    $s->trigger("res", "");
    is($result, ":EMPTY,res:RES", "Got resource after the trigger. undef(empty) resource and 'res' resource.");
}

{
    note('--- select() with invalid callback');
    my $s = new_ok('Async::Selector');
    my $msg = qr/must be a coderef/i;
    throws_ok {$s->select(undef, res => 100)} $msg, "callback must not be undef";
    throws_ok {$s->select("string", res => 100)} $msg, "... or a string";
    throws_ok {$s->select([1, 2, 10], res => 100)} $msg, "... or an arrayref";
    throws_ok {$s->select({hoge => "foo"})} $msg, "... or a hashref.";
}

{
    note('--- select() with no resource');
    my $s = new_ok('Async::Selector');
    my $id = undef;
    warning_is {$id = $s->select(sub { return 1 })} undef, "Selecting no resource is no problem, but useless.";
    ok(defined($id), "Got ID for selection for no resource");
    warning_is {$s->cancel($id)} undef, "Cancel the useless selection without warning.";
}

{
    note('--- unregister() non-existent resource');
    my $s = new_ok('Async::Selector');
    $s->register(res => sub { return 'FOOBAR'});
    is(int($s->resources), 1, "one resource registered");
    warning_is { $s->unregister(qw(this does not exist)) } undef, "non-existent resources are silently ignored in unregister().";
    warning_is { $s->unregister(qw(unknown res)) } undef, "you can unregister() existent resource as well as non-existent one.";
    is(int($s->resources), 0, "no resource registered");
}


note('--- unregister() undef resource');
note('--- unregister() while selection is active.');

note('--- register() with no resource');
note('--- register() undef resource');
note('--- register() with invalid providers (undef, scalar, arrayref, hashref)');

note('--- trigger() to non-existent resource');
note('--- trigger() nothing');

note('--- cancel() undef selection');
note('--- cancel() multiple times');

done_testing();
