use strict;
use warnings;

use Async::Selector;


{
    ## Multiple resources, multiple watches
    
    my $selector = Async::Selector->new();
    my $a = 5;
    my $b = 6;
    my $c = 7;
    $selector->register(
        a => sub { my $t = shift; return $a >= $t ? $a : undef },
        b => sub { my $t = shift; return $b >= $t ? $b : undef },
        c => sub { my $t = shift; return $c >= $t ? $c : undef },
    );
    $selector->watch(a => 10, sub {
        my ($watcher, %res) = @_;
        print "Select 1: a is $res{a}\n";
        $watcher->cancel();
    });
    $selector->watch(
        a => 12, b => 15, c => 15,
        sub {
            my ($watcher, %res) = @_;
            foreach my $key (sort keys %res) {
                print "Select 2: $key is $res{$key}\n";
            }
            $watcher->cancel();
        }
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
    ## one-shot and persistent watches
    my $selector = Async::Selector->new();
    my $A = "";
    my $B = "";
    $selector->register(
        A => sub { my $in = shift; return length($A) >= $in ? $A : undef },
        B => sub { my $in = shift; return length($B) >= $in ? $B : undef },
    );

    my $watcher_a = $selector->watch(A => 5, sub {
        my ($watcher, %res) = @_;
        print "A: $res{A}\n";
        $watcher->cancel(); ## one-shot callback
    });
    my $watcher_b = $selector->watch(B => 5, sub {
        my ($watcher, %res) = @_;
        print "B: $res{B}\n";
        ## persistent callback
    });

    ## Trigger the resources.
    ## Execution order of watcher callbacks is not guaranteed.
    ($A, $B) = ('aaaaa', 'bbbbb');
    $selector->trigger('A', 'B');   ## -> B: bbbbb
                                    ## -> A: aaaaa
    print "--------\n";
    ## $watcher_a is already canceled.
    ($A, $B) = ('AAAAA', 'BBBBB');
    $selector->trigger('A', 'B');   ## -> B: BBBBB
    print "--------\n";

    $B = "CCCCCCC";
    $selector->trigger('A', 'B');   ## -> B: CCCCCCC
    print "--------\n";

    $watcher_b->cancel();
    $selector->trigger('A', 'B');        ## Nothing happens.
}

