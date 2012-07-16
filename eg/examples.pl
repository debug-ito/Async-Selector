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
    ## Auto-remove and non-remove selections
    ;
}

