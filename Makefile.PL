use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Async::Selector',
    AUTHOR              => q{Toshio Ito <debug.ito@gmail.com>},
    VERSION_FROM        => 'lib/Async/Selector.pm',
    ABSTRACT_FROM       => 'lib/Async/Selector.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Carp' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Async-Selector-*' },
);
