use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FrameNet::QueryData',
    AUTHOR              => 'Nils Reiter <reiter@cpan.org>',
    VERSION_FROM        => 'lib/FrameNet/QueryData.pm',
    ABSTRACT_FROM       => 'lib/FrameNet/QueryData.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FrameNet-QueryData-*' },
);