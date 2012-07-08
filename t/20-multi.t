
use strict;
use warnings;
use Test::More;



package Sample::Resource;
use strict;
use warnings;

sub new {
    my ($class, $name, $selector) = @_;
    my $self =  bless {
        name => $name,
        selector => $selector,
        content => ""
    }, $class;
    return $self;
}

sub provider {
    my $self = shift;
    return sub {
        my ($min_length) = @_;
        return length($self->{content}) >= $min_length ? $self->{content} : undef;
    };
}

sub set {
    
}

package main;

note('Test for N-resource M-selection.');

done_testing();

