use strict;
use warnings;
use Test::More;

note('Test for erroneous situations.');

note('--- select() non-existent resource');
note('--- select() undef resource');
note('--- select() with no callback');
note('--- select() with no resource');

note('--- unregister() while selection is active.');
note('--- unregister() non-existent resource');
note('--- unregister() undef resource');

note('--- register() with no resource');
note('--- register() with invalid providers');

note('--- trigger() to non-existent resource');
note('--- trigger() nothing');

note('--- cancel() undef selection');
note('--- cancel() multiple times');

done_testing();
