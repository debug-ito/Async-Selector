use strict;
use warnings;
use Test::More;
use Test::Builder;
use Test::Warn;
use Test::Exception;
use Async::Selector;

note('Test for erroneous situations.');

sub catter {
    my ($result_ref, $ret_val) = @_;
    return sub {
        my ($selection, %res) = @_;
        $$result_ref .= join ',', map { "$_:$res{$_}" } sort {$a cmp $b} grep { defined($res{$_}) } keys %res;
        return $ret_val;
    };
}

sub checkSNum {
    my ($selector, $selection_num) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(int($selector->selections), $selection_num, "$selection_num selections.");
}

sub checkRNum {
    my ($selector, $resource_num) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is(int($selector->resources), $resource_num, "$resource_num resources.");
}


{
    note('--- select() non-existent resource');
    my $s = new_ok('Async::Selector');
    $s->register("res" => sub { my $in = shift; return $in ? "RES" : undef });
    checkSNum $s, 0;
    my $result = "";
    warning_is { $s->select(unknown => 100, catter(\$result, 1)) } undef, "No warning for selecting non-existent resource.";
    checkSNum $s, 1;
    warning_is { $s->select(res => 1, unknown => 20, catter(\$result, 1)) } undef, "... neither when existent resource is selected as well.";
    checkSNum $s, 1;
    is($result, "res:RES", "existent resource is provided as usual.");
    $result = "";
    $s->register("unknown" => sub { return 10 });
    is($result, "", "The result is empty");
    $s->trigger("unknown");
    is($result, "unknown:10", "The result is now 'token' because the resource 'unknown' now exists and be triggered.");
    checkSNum $s, 0;
}

{
    note('--- select() undef resource');
    my $s = new_ok('Async::Selector');
    my $result = "";
    checkSNum $s, 0;
    warning_like {$s->select(undef, 100, res => 200, catter(\$result, 1))}
        qr/uninitialized/i, "Selecting undef is treated as selecting a resource named empty string.";
    checkSNum $s, 1;
    $s->register(res => sub { return "RES" }, "" => sub { return "EMPTY" });
    is($result, "", "result is empty before trigger");
    $result = "";
    checkSNum $s, 1;
    $s->trigger("res", "");
    checkSNum $s, 0;
    is($result, ":EMPTY,res:RES", "Got resource after the trigger. undef(empty) resource and 'res' resource.");
}

{
    note('--- select() with invalid callback');
    my $s = new_ok('Async::Selector');
    my $msg = qr/must be a coderef/i;
    throws_ok {$s->select(res => 100, undef)} $msg, "callback must not be undef";
    throws_ok {$s->select(res => 100, "string")} $msg, "... or a string";
    throws_ok {$s->select(res => 100, [1, 2, 10])} $msg, "... or an arrayref";
    throws_ok {$s->select(res => 100, {hoge => "foo"})} $msg, "... or a hashref.";
    checkSNum $s, 0;
}

{
    note('--- select() with no resource');
    my $s = new_ok('Async::Selector');
    my $selection = undef;
    my @result = ();
    warning_is {$selection = $s->select(sub { push(@result, 'token'); return 0 })}
        undef, "select() finishes with no warning even if it is supplied with no resource selection.";
    ok(!defined($selection), "... it returns no selection object. selection is silently rejected.");
    is(int(@result), 0, "... callback is not executed, because the selection is rejected.");
    checkSNum $s, 0;

    @result = ();
    warning_is {$selection = $s->select_et(sub { push(@result, 'token'); return 0 })}
        undef, "The behavior is the same for select_et().";
    ok(!defined($selection), "... it returns no selection object.");
    is(int(@result), 0, "... callback is not executed, because the selection is rejected.");
    checkSNum $s, 0;
}

{
    note('--- select() without callback');
    my $s = new_ok('Async::Selector');
    throws_ok { $s->select(a => 10, b => 20) }
        qr/must be a coderef/i, 'Throw exception when select() is called without callback';
    throws_ok { $s->select() }
        qr/must be a coderef/i, 'Throw exception when select() is called without any argument';
    note('--- -- what if condition input is a coderef?');
    warning_like { $s->select(a => sub {10}) }
        qr(odd number)i, 'Warning from warning pragma when select() is called without callback but condition input is a coderef';
    my $fired = 0;
    $s->register(a => sub {
        my ($in) = @_;
        $fired = 1;
        ok(!defined($in), "condition input is undef.");
        return 1;
    });
    is(int($s->selections), 1, "selection is alive");
    $s->trigger('a');
    is($fired, 1, "selection fired.");
    is(int($s->selections), 0, "currently no selection.");
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

{
    note('--- unregister() undef resource');
    my $s = new_ok('Async::Selector');
    $s->register('res' => sub { return 10 });
    is(int($s->resources), 1, "One resource.");
    warning_is { $s->unregister(undef) } undef, "unregister(undef) is silently ignored.";
    is(int($s->resources), 1, "Still one resource.");
    warning_is { $s->unregister(undef, 'res') } undef, "unregister(undef, 'res'). undef is ignored.";
    is(int($s->resources), 0, "Unresgistered.");
}

{
    note('--- unregister() a resource multiple times.');
    my $s = new_ok('Async::Selector');
    $s->register('res' => sub { return 10 });
    is(int($s->resources), 1, "One resource.");
    warning_is { $s->unregister('res', 'res', 'res') } undef, "unregister() the same resource multiple times at once is no problem.";
    is(int($s->resources), 0, "Unregistered.");
}

{
    note('--- unregister() while selection is active.');
    my $s = new_ok('Async::Selector');
    my $res = 0;
    $s->register('res' => sub { my $in = shift; return $res >= $in ? $res : undef });
    my $result = "";
    my @selections = ();
    push @selections, $s->select('res' => 5, catter(\$result, 0));
    push @selections, $s->select('res' => 10, catter(\$result, 1));
    checkSNum $s, 2;
    warning_is { $s->unregister('res') } undef, "unregister() does not warn even when the deleted resource is now selected.";
    checkSNum $s, 2;
    $res = 100;
    $s->trigger('res');
    is($result, "", "Resource 'res' is no longer registered, so triggering it does no effect.");
    checkSNum $s, 2;
}

{
    note('--- register() with no resource');
    my $s = new_ok('Async::Selector');
    checkRNum $s, 0;
    warning_is { $s->register() } undef, "It's OK to call register() with no argument. It does nothing.";
    checkRNum $s, 0;
}

{
    note('--- register() undef resource');
    my $s = new_ok('Async::Selector');
    checkRNum $s, 0;
    warnings_like { $s->register(undef, sub { return 10 }) }
        qr/uninitialized/i, "undef resource causes warning, and it's treated as empty-named resource.";
    checkRNum $s, 1;
    is(($s->resources)[0], "", "Empty named resource");
    my $result = "";
    checkSNum $s, 0;
    $s->select('', 10, catter(\$result, 1));
    is($result, ":10", "Get result from a selection");
    checkSNum $s, 0;
}

{
    note('--- register() with invalid providers (undef, scalar, arrayref, hashref)');
    my $s = new_ok('Async::Selector');
    checkRNum $s, 0;
    throws_ok { $s->register(res => undef) } qr(must be coderef)i, "Resource provider must not be undef";
    throws_ok { $s->register(res => 'string') } qr(must be coderef)i, "... or a string";
    throws_ok { $s->register(res => [10, 20]) } qr(must be coderef)i, "... or an arrayref";
    throws_ok { $s->register(res => {foo => 'bar'}) } qr(must be coderef)i, "... or a hashref";
    checkRNum $s, 0;
}

{
    note('--- trigger() to non-existent resource');
    my $s = new_ok('Async::Selector');
    warning_is { $s->trigger(qw(this does not exist)) } undef, "trigger() non-existent resources is OK. Just ignored.";
    $s->select(want => 10, sub { fail("Callback fired."); return 0 });
    checkSNum $s, 1;
    warning_is { $s->trigger(qw(that does not here)) } undef, "trigger() non-selected resource does not fire selection.";
    
    note('--- trigger() nothing');
    warning_is { $s->trigger() } undef, "trigger() with no argument is OK (but meaningless).";
}

{
    note('--- $selector->cancel() undef selection');
    my $s = new_ok('Async::Selector');
    warning_is { $s->cancel(undef, undef, undef) } undef, "cancel(undef) is OK.";
    my $selection = $s->select(want => 10, sub { fail("Callback fired."); return 1 });
    checkSNum $s, 1;
    is(($s->selections)[0], $selection, "selection object is $selection.");
    warning_is { $s->cancel(undef) } undef, "cancel(undef) does nothing.";
    checkSNum $s, 1;
    note('--- -- cancel() multiple times');
    warning_is { $s->cancel($selection, $selection, $selection) } undef, "It's OK to cancel() the same Selection object multiple times at once.";
    checkSNum $s, 0;
    warning_is { $s->cancel($selection, 'this', "not", "exists") } undef, "cancel() non-existent selections is OK. Ignored.";
}

done_testing();
