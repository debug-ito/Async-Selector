package Async::Selector::Aggregator;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use Carp;

sub new {
    my ($class) = @_;
    my $self = bless {
        is_active => 1,
        watchers => [],
    }, $class;
    return $self;
}

sub add {
    my ($self, $watcher) = @_;
    if(!defined($watcher) || !blessed($watcher) || !$watcher->can('active') || !$watcher->can('cancel')) {
        croak('watcher must be either Async::Selector::Watcher or Async::Selector::Aggregator');
    }
    if($self eq $watcher) {
        croak('you cannot add the aggregator itself.');
    }
    my $w_active = $watcher->active;
    my $s_active = $self->active;
    if($w_active && !$s_active) {
        $watcher->cancel();
    }elsif(!$w_active && $s_active) {
        $self->cancel();
    }
    push(@{$self->{watchers}}, $watcher);
}

sub watchers {
    my ($self) = @_;
    return @{$self->{watchers}};
}

sub active {
    my ($self) = @_;
    return $self->{is_active};
}

sub cancel {
    my ($self) = @_;
    $self->{is_active} = 0;
    foreach my $w ($self->watchers) {
        $w->cancel();
    }
}

our $VERSION = '1.02';

1;

=pod

=head1 NAME

Async::Selector::Aggregator - aggregator of watchers and other aggregators

=head1 SYNOPSIS

    Write SYNOPSIS!!

=head1 DESCRIPTION

L<Async::Selector::Aggregator> is an object that keeps L<Async::Selector::Watcher> objects and/or other aggregator objects
and treats them as a single watcher.
Using L<Async::Selector::Aggregator>, you can ensure that a certain set of watchers are always cancelled at the same time.
This is useful when you use multiple L<Async::Selector>s and treat them as a single selector.

Watchers and aggregators kept in an L<Async::Selector::Aggregator> are in one of the two states;
they are all active or they are all inactive.
No intermediate state is possible unless you call C<cancel()> method on individual watchers.
You should not C<cancel> individual watchers once you aggregate them into an L<Async::Selector::Aggregator> object.


=head1 CLASS METHODS

=head2 $aggregator = Async::Selector::Aggregator->new()

Creates a new L<Async::Selector::Aggregator> object. It takes no argument.

A newly created aggregator is active.

=head1 OBJECT METHODS

=head2 $aggregator->add($watcher)

Adds the given C<$watcher> to the C<$aggregator>.
The C<$watcher> may be an L<Async::Selector::Watcher> object or an L<Async::Selector::Aggregator> object.

If C<$aggregator> is active and C<$watcher> is inactive, C<< $aggregator->cancel() >> is automatically called.
If C<$aggregator> is inactive and C<$watcher> is active, C<< $watcher->cancel() >> is automatically called.
This is because all watchers in the C<$aggregator> must share the same state.

If C<$watcher> is the same instance as C<$aggregator>, it croaks.

=head2 @watchers = $aggregator->watchers()

Returns the list of all watchers kept in the C<$aggregator>.

=head2 $is_active = $aggregator->active()

Returns true if the C<$aggregator> is active. Returns false otherwise.


=head2 $aggregator->cancel()

Cancels the C<$aggregator>, that is, change its state into inactive.
It also cancels all watchers kept in the C<$aggregator>.


=head1 AUTHOR

Toshio Ito C<< <toshioito at cpan.org> >>

=cut
