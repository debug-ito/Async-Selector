use strict;
use warnings;
use Test::More;
use Test::Warn;
use Async::Selector;

note('--- For backward compatibility select() API can take the callback from the first positional argument.');

my $s = new_ok('Async::Selector');
my $resource_a = 0;
$s->register(a => sub {
    my $in = shift;
    return $resource_a > $in ? $resource_a : undef;
});


sub selnum {
    my ($num) = @_;
    is(int($s->selections), $num, "selection num is $num");
}

my %result = ();

sub collect {
    my ($auto_cancel) = @_;
    return sub {
        my ($id, %res) = @_;
        foreach my $key (keys %res) {
            if(!exists($result{$key})) {
                $result{$key} = $res{$key}
            }elsif(ref($result{$key}) eq 'ARRAY') {
                push(@{$result{$key}}, $res{$key});
            }else {
                $result{$key} = [$result{$key}, $res{$key}];
            }
        }

        return $auto_cancel;
    };
}

foreach my $method (qw(select select_lt)) {
    %result = ();
    warning_is { $s->$method(collect(0), a => -10) } undef, "No warning for $method().";
    is_deeply(\%result, {a => 0}, "callback fired.");
    selnum 1;
    %result = ();
    $s->trigger('a');
    is_deeply(\%result, {a => 0}, "callback fired.");
    $s->cancel($s->selections);
    selnum 0;
}

%result = ();
warning_is { $s->select_et(collect(0), a => -10) } undef, 'No warning for select_et().';
is_deeply(\%result, {}, "callback is not fired because it's ET");
selnum 1;
$s->trigger('a');
is_deeply(\%result, {a => 0}, "callback fired");
selnum 1;
$s->cancel($s->selections);
selnum 0;

my $resource_b = 0;
$s->register(b => sub {
    my $in_sub = shift;
    return $resource_b < $in_sub->() ? $resource_b : undef;
});

%result = ();
warning_is { $s->select(collect(0), a => -10, b => sub {-10}) } undef, "No warning for multiple resources.";
is_deeply(\%result, {a => 0, b => undef}, "callback fired");

%result = ();
($resource_a, $resource_b) = (-20, -20);
$s->trigger('a', 'b');
is_deeply(\%result, {a => undef, b => -20}, "callback fired");

$s->cancel($s->selections);
selnum 0;

($resource_a, $resource_b) = (0, 0);
$s->trigger('a', 'b');

%result = ();
$s->select(collect(1), a => 10, b => sub {-10});
$s->select(collect(1), a => 20, b => sub {-20});
$s->select(collect(1), a => 30, b => sub {-30});
is_deeply(\%result, {}, "no one fired.");
selnum 3;
($resource_a, $resource_b) = (15, 0);
$s->trigger('a', 'b');
is_deeply(\%result, {a => 15, b => undef}, "1st fire");
selnum 2;
%result = ();
($resource_a, $resource_b) = (15, -25);
$s->trigger('a', 'b');
is_deeply(\%result, {a => undef, b => -25}, "2nd fire");
selnum 1;
%result = ();
($resource_a, $resource_b) = (32, -32);
$s->trigger('a', 'b');
is_deeply(\%result, {a => 32, b => -32}, "3rd fire");
selnum 0;




done_testing();
