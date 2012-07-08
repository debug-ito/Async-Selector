use strict;
use warnings;
use Test::More;
use Test::Builder;

package Sample::Resources;
use strict;
use warnings;

sub new {
    my ($class, $selector, @names) = @_;
    my $self =  bless {
        selector => $selector,
        resources => { map {$_ => ""} @names },
    }, $class;
    my %register_params = ();
    foreach my $name (@names) {
        $register_params{$name} = sub {
            my ($min_length) = @_;
            return length($self->{resources}{$name}) >= $min_length ? $self->{resources}{$name} : undef;
        };
    }
    $selector->register(%register_params);
    return $self;
}

sub get {
    my ($self, @names) = @_;
    return @{$self->{resources}}{@names};
}

sub set {
    my ($self, %vals) = @_;
    @{$self->{resources}}{keys %vals} = values %vals;
    $self->{selector}->trigger(keys %vals);
}

package main;

BEGIN {
    use_ok('Async::Selector');
}

sub collector {
    my ($result_ref, $ret_val) = @_;
    return sub {
        my ($id, %res) = @_;
        push(@$result_ref, map { sprintf("%s:%s", $_, $res{$_}) } grep { defined($res{$_}) } keys %res);
        return $ret_val;
    };
}

sub checkResult {
    my ($result_ref, @exp_list) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    cmp_ok(int(@$result_ref), "==", int(@exp_list), sprintf("result num == %d", int(@exp_list)));
    foreach my $exp_str (@exp_list) {
        ok((grep { $_ eq $exp_str } @$result_ref), "result includes $exp_str");
    }
}

note('Test for N-resource M-selection.');

{
    note('--- N-resource, 1-selection.');
    my $N = 5;
    my $s = new_ok('Async::Selector');
    my $rs = Sample::Resources->new($s, 1 .. $N);
    my @result = ();
    $s->select(collector(\@result, 1), 1 => 3, 2 => 4, 3 => 2, 4 => 9, 5 => 2);
    checkResult \@result;
    $rs->set(1 => "sk", 2 => "sas", 3 => "", 4 => "abcdefgh", 5 => "Y");
    checkResult \@result;
    $rs->set(1 => "ab", 2 => "asas", 3 => "BB",               5 => "ybb");
    checkResult \@result, qw(2:asas 3:BB 5:ybb);
    @result = ();
    $rs->set(map {$_ => "this_is_a_long_string"} 1 .. $N);
    cmp_ok(int(@result), "==", 0, "no result because the selection is removed.");

    @result = ();
    my $id = $s->select(collector(\@result, 0), 1 => 0, 2 => 3, 3 => 4);
    checkResult \@result, qw(1:this_is_a_long_string 2:this_is_a_long_string 3:this_is_a_long_string);
    @result = ();
    $rs->set(1 => "", 2 => "aa", 3 => "bb", 4 => "cc", 5 => "dd");
    checkResult \@result, qw(1:);
    @result = ();
    $s->trigger(1 .. $N);
    checkResult \@result, qw(1:);
    @result = ();
    $s->trigger(3);
    checkResult \@result, qw(1:);
    @result = ();
    $rs->set(2 => "aaa", 3 => "bbbb", 4 => "ccccc", 5 => "dddddd");
    checkResult \@result, qw(1: 2:aaa 3:bbbb);

    note("--- -- if the triggered resource is not selected, the selection callback is not executed.");
    @result = ();
    $s->trigger(4, 5);
    checkResult \@result;

    $s->cancel($id);

    @result = ();
    $rs->set(map {$_ => ""} 1 .. $N);
    checkResult \@result;

    @result = ();
    $id = $s->select(collector(\@result, 0), 3 => 3, 4 => 4, 5 => 5);
    checkResult \@result;
    @result = ();
    $rs->set(1 => "a", 2 => "b", 3 => "c", 4 => "d", 5 => "e");
    checkResult \@result;
    @result = ();
    $rs->set(1 => "a" x 3, 2 => "b" x 3, 3 => "c" x 3, 4 => "d" x 3, 5 => "e" x 3);
    checkResult \@result, qw(3:ccc);
    @result = ();
    $rs->set(1 => "a" x 4, 2 => "b" x 4, 3 => "c" x 4, 4 => "d" x 4, 5 => "e" x 4);
    checkResult \@result, qw(3:cccc 4:dddd);
    @result = ();
    $rs->set(1 => "a" x 5, 2 => "b" x 5, 3 => "c" x 5, 4 => "d" x 5, 5 => "e" x 5);
    checkResult \@result, qw(3:ccccc 4:ddddd 5:eeeee);
}

{
    note('--- 1-resource, M-selections');
    note('--- -- mix auto-remove and non-remove selections');
    note('--- -- cancel() some of the selections');
}

{
    note('--- N-resource, M-selections');
}

done_testing();

