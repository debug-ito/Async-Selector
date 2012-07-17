use strict;
use warnings;

use Async::Selector;


{
    ## Multiple resources, multiple selections
    
    my $selector = Async::Selector->new();
    my $a = 5;
    my $b = 6;
    my $c = 7;
    $selector->register(
        a => sub { my $t = shift; return $a >= $t ? $a : undef },
        b => sub { my $t = shift; return $b >= $t ? $b : undef },
        c => sub { my $t = shift; return $c >= $t ? $c : undef },
    );
    $selector->select(
        sub {
            my ($id, %res) = @_;
            print "Select 1: a is $res{a}\n";
            return 1;
        },
        a => 10
    );
    $selector->select(
        sub {
            my ($id, %res) = @_;
            foreach my $key (sort keys %res) {
                next if not defined($res{$key});
                print "Select 2: $key is $res{$key}\n";
            }
            return 1;
        },
        a => 12, b => 15, c => 15,
    );

    ($a, $b, $c) = (11, 14, 14);
    $selector->trigger(qw(a b c));  ## -> Select 1: a is 11
    print "---------\n";
    ($a, $b, $c) = (12, 14, 20);
    $selector->trigger(qw(a b c));  ## -> Select 2: a is 12
                                    ## -> Select 2: c is 20
}

print "==============\n";

{
    ## Auto-cancel and non-cancel selections
    my $selector = Async::Selector->new();
    my $A = "";
    my $B = "";
    $selector->register(
        A => sub { my $in = shift; return length($A) >= $in ? $A : undef },
        B => sub { my $in = shift; return length($B) >= $in ? $B : undef },
    );

    my $sel_a = $selector->select(
        sub {
            my ($id, %res) = @_;
            print "A: $res{A}\n";
            return 1; ## auto-cancel
        },
        A => 5
    );
    my $sel_b = $selector->select(
        sub {
            my ($id, %res) = @_;
            print "B: $res{B}\n";
            return 0; ## non-cancel
        },
        B => 5
    );

    ## Trigger the resources.
    ## Execution order of selection callbacks is not guaranteed.
    ($A, $B) = ('aaaaa', 'bbbbb');
    $selector->trigger('A', 'B');   ## -> B: bbbbb
                                    ## -> A: aaaaa
    print "--------\n";
    ## $sel_a is automatically canceled.
    ($A, $B) = ('AAAAA', 'BBBBB');
    $selector->trigger('A', 'B');   ## -> B: BBBBB
    print "--------\n";

    $B = "CCCCCCC";
    $selector->trigger('A', 'B');        ## -> B: CCCCCCC
    print "--------\n";

    $selector->cancel($sel_b);
    $selector->trigger('A', 'B');        ## Nothing happens.
}

