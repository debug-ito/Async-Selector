package Async::Selector::Watcher;
use strict;
use warnings;

sub new {
    my ($class, $selector, $conditions, $cb) = @_;
    return bless {
        selector => $selector,
        conditions => $conditions,
        cb => $cb,
    }, $class;
}

sub call {
    my ($self) = @_;
    return $self->{cb}->(@_);
}

sub detach {
    my ($self) = @_;
    $self->{selector} = undef;
}

sub cancel {
    my ($self) = @_;
    return $self if not defined($self->{selector});
    my $selector = $self->{selector};
    $self->detach();
    $selector->cancel($self);
    return $self;
}

sub conditions {
    my ($self) = @_;
    return %{$self->{conditions}};
}

sub resources {
    my ($self) = @_;
    return keys %{$self->{conditions}};
}

sub active {
    my ($self) = @_;
    return defined($self->{selector});
}

1;


