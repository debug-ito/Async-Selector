package Async::Selector::Watcher;
use strict;
use warnings;

sub new {
    my ($class, $selector, $conditions, $cb) = @_;
    return bless {
        selector => $selector,
        conditions => $conditions,
        cb => $cb,
        check_all => 0,
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

sub getCheckAll {
    my ($self) = @_;
    return $self->{check_all};
}

sub setCheckAll {
    my ($self, $check_all) = @_;
    $self->{check_all} = $check_all;
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

=pod

=head1 NAME

Async::Selector::Watcher - Representation of resource watch in Async::Selector

=head1 SYNOPSIS

B<TODO: Write SYNOPSIS, check its correctness and paste it here.>


=head1 DESCRIPTION

L<Async::Selector::Watcher> is an object that stores information about a resource watch in L<Async::Selector> module.
It also provides its user with a way to cancel the watch.


=head1 CLASS METHODS

Nothing.

L<Async::Selector::Watcher> objects are created by C<watch()>, C<watch_lt()> and C<watch_et()> methods of L<Async::Selector>.


=head1 OBJECT METHODS

In the following description, C<$watcher> is an L<Async::Selector::Watcher> object.

=head2 $watcher->cancel();

Cancel the watch.

The C<$watcher> then becomes inactive and is removed from the L<Async::Selector> object it used to belong to.

You should call C<cancel()> method on every watchers at some point.
Otherwise, watchers would persist in an L<Async::Selector> obejct, causing memory leak.

=head2 $is_active = $watcher->active();

Returns true if the L<Async::Selector::Watcher> is active. Returns false otherwise.

Active watchers are the ones in L<Async::Selector> objects, watching some of the Selector's resources.
Callback functions of active watchers can be executed if the watched resources get available.

Inactive watchers are the ones that have been removed from L<Async::Selector> objects.
Their callback functions are never executed any more.


=head2 @resources = @watcher->resources();

Returns the list of resource names that are watched by this L<Async::Selector::Watcher> object.



=head2 %conditions = $watcher->conditions();

Returns a hash whose keys are the resource names that are watched by this L<Async::Selector::Watcher> object,
and values are the condition inputs for the resources.

C<%conditions> are the same as C<< $name => $condition_input >> pairs that were given to C<watch()> method of L<Async::Selector>.


=head1 SEE ALSO

L<Async::Selector>


=head1 AUTHOR

Toshio Ito, C<< <debug.ito at gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.



=cut


