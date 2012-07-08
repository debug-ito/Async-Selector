package Async::Selector;

use 5.006;
use strict;
use warnings;

use Carp;


=pod

=head1 NAME

Async::Selector - level-triggered resource observer like select(2)


=head1 VERSION

0.01

=cut

our $VERSION = "0.01";


=pod

=head1 SYNOPSIS




=head1 DESCRIPTION

L<Async::Selector> is an object that observes registered resources
and executes callbacks when some of the resources are available.
Thus it is an implementation of the Observer pattern like L<Event::Notify>,
but the important difference is that L<Async::Selector> is B<level-triggered> like C<select(2)> system call.

Basic usage of L<Async::Selector> is as follows:

=over

=item 1.

Register as many resources as you like by C<register()> method.

A resource has its name and resource provider.
A resource provier is a subroutine reference that returns some data (or C<undef> if it's not available).


=item 2.

Select as many resources as you like by C<select()> method.

When any of the selected resources gets available, a callback function is executed
with the available resource data.

Note that if some of the selected resources is available when calling C<select()> method,
it executes the callback function immediately.
That's because L<Async::Selector> is level-triggered.


=item 3.

Notify the L<Async::Selector> object by C<trigger()> method that some of the registered resources have changed.


The L<Async::Selector> object then checks if any of the selected resources gets available.
In this case the callback function given by C<select()> method is executed.


=back


=head1 CLASS METHODS


=head2 $selector = Async::Selector->new();

Creates an L<Async::Selector> object. It takes no parameters.


=cut


sub new {
   my ($class) = @_;
   my $self = bless {
       resources => {},
       selections => {},
   }, $class;
   return $self;
}

sub _check {
   my ($self, $selection_id) = @_;
   my %results = ();
   my $fired = 0;
   my $selection = $self->{$selection_id};
   return 0 if !defined($selection);
   while(my ($res_key, $input) = each(%{$selection->{conditions}})) {
       if(!defined($self->{resources}{$res_key})) {
           $results{$res_key} = undef;
           next;
       }
       ## How about condition input being coderef?? This is up to how resources are given.
       $results{$res_key} = $self->{resources}{$res_key}->($input);
       if(defined($results{$res_key})) {
           $fired = 1;
       }
   }
   return 0 if !$fired;
   if($selection->{cb}->(%results)) {
       $self->cancel($selection_id);
   }
   return 1;
}

=pod

=head1 OBJECT METHODS

=head2 $selector->register($name => $provider->($condition_input), ...);

Registers resources with the object.
A resource is described as a pair of resource name and resource provider.
You can register as many resources as you like.

The resource name (C<$name>) is an arbitrary string.
It is used to select the resource in C<select()> method.
If C<$name> is already registered with C<$selector>,
the resource provider is updated with C<$provider> and the old one is discarded.

The resource provider (C<$provider>) is a subroutine reference.
Its return value is supposed to be a scalar data of the resource if it's available,
or C<undef> if it's NOT available.

C<$provider> subroutine takes a scalar argument (C<$condition_input>),
which is given in arguments of C<select()> method.
C<$provider> can decide whether to provide the resource according to C<$condition_input>.

C<register()> method returns C<$selector> object itself.


=cut

sub register {
   my ($self, %providers) = @_;
   my @error_keys = ();
   while(my ($key, $provider) = each(%providers)) {
       if(ref($provider) ne 'CODE') {
           push(@error_keys, $key);
       }
   }
   if(@error_keys) {
       croak("Providers must be coderef for keys: " . join(",", @error_keys));
       return;
   }
   @{$self->{resources}}{keys %providers} = values %providers;
   return $self;
}

=pod

=head2 $selector->unregister($name, ...);

Unregister resources from C<$selector> object.

C<$name> is the name of the resource you want to unregister.
You can unregister as many resources as you like.

C<unregister()> returns C<$selector> object itself.

=cut

sub unregister {
    my ($self, @names) = @_;
    delete @{$self->{resources}}{grep { defined($_) } @names};
    return $self;
}


=pod

=head2 $selection_id = $selector->select($callback->(%resources), $name => $condition_input, ...);

Selects resources.
A resource selection is described as a pair of resource name and condition input for the resource.
You can select as many resources as you like.

C<$callback> is a subroutine reference that is executed when any of the selected resources gets available.
Its argument (C<%resources>) is a hash whose key is the resource name and value is the resource data.
Note that some values in C<%resources> can be C<undef>, meaning that those resources are not available.
Note also that C<$callback> is executed before C<select()> method returns
if some of the selected resources is already available.

C<$callback> is supposed to return a boolean value.
If the return value is true, the selection is removed after the execution of C<$callback>.
If the return value is false, the selection remains.

C<$name> is the resource name that you want to select. It is the name given in C<register()> method.

C<$condition_input> describes the condition the resource has to meet to be considered as "available".
C<$condition_input> is an arbitrary scalar, and it's interpretation is up to the resource provider.

C<select()> method returns an ID for the selection (C<$selection_id>),
which can be used to cancel the selection in C<cancel()> method.
If C<$callback> is executed before C<select()> returns and C<$callback> returns true,
C<select()> returns C<undef> because the selection is already removed.


=head2 $selection_id = $selector->select_lt(...);

C<select_lt()> method is an alias for C<select()> method.


=head2 $selection_id = $selector->select_et(...);

This method is just like C<select()> method but it emulates edge-triggered selection.

To emulate edge-triggered behavior, C<select_et()> won't execute
the C<$callback> before it returns.
The C<$callback> is executed only when some of the selected resources
gets available via C<trigger()> method.

=cut

sub select_et {
    my ($self, $cb, %conditions) = @_;
    my $selection = {
        conditions => \%conditions,
        cb => $cb,
    };
    my $id = "$selection";
    $self->{selections}{$id} = $selection;
    return $id;
}

sub select_lt {
    my ($self, $cb, %conditions) = @_;
    my $id = $self->select_et($cb, %conditions);
    $self->_check($id);
    return defined($self->{selections}{$id}) ? $id : undef;
}

*select = \&select_lt;


=pod

=head2 $selector->cancel($selection_id, ...);

Cancel selections so that their callback functions won't be executed.

C<$selection_id> is the selection ID you want to cancel.
It is returned by C<select()> method.
You can specify as many C<$selection_id>s as you like.

C<cancel()> method returns C<$selector> object itself.

=cut

sub cancel {
   my ($self, @ids) = @_;
   delete @{$self->{selections}}{grep { defined($_) } @ids};
   return $self;
}

=pod

=head2 $selector->trigger($name, ...);

Notify C<$selector> that the resources specified by C<$name>s may be changed.

C<$name> is the name of the resource that have been changed.
You can specify as many C<$name>s as you like.

C<trigger()> method returns C<$selector> object itself.

=cut

sub trigger {
   my ($self, @resources) = @_;
   my @affected_selections = ();
   selec_loop: foreach my $selection (values %{$self->{selections}}) {
       foreach my $res (@resources) {
           next if !defined($res);
           if(defined($selection->{conditions}{$res})) {
               push(@affected_selections, $selection);
               next selec_loop;
           }
       }
   }
   foreach my $selection (@affected_selections) {
       $self->_check($selection);
   }
   return $self;
}

=pod

=head2 @resouce_names = $selector->resources();

Returns the list of registered resource names.

=cut

sub resources {
    my ($self) = @_;
    return keys %{$self->{resources}};
}


=head1 AUTHOR

Toshio Ito, C<< <debug.ito at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-async-selector at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Async-Selector>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Async::Selector


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Async-Selector>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Async-Selector>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Async-Selector>

=item * Search CPAN

L<http://search.cpan.org/dist/Async-Selector/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Toshio Ito.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Async::Selector
