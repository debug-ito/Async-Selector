use strict;
use warnings;


use Async::Selector;

my $selector = Async::Selector->new();

## Register resource
my $resource = "some text.";  ## 10 bytes

$selector->register(resource_A => sub {
    my $threshold = shift;
    return length($resource) >= $threshold ? $resource : undef;
});


## Select the resource with a callback.
$selector->select(
    resource_A => 20,  ## Tell me when the resource gets more than 20 bytes!
    sub {
        my ($id, %resource) = @_;
        print "$resource{resource_A}\n";
        return 1;
    }
);


## Append data to the resource
$resource .= "data";  ## 14 bytes
$selector->trigger('resource_A'); ## Nothing happens

$resource .= "more data";  ## 23 bytes
$selector->trigger('resource_A'); ## The callback prints 'some text.datamore data'


