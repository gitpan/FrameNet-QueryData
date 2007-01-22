#!perl -T

use Test::More tests => 5;
use FrameNet::QueryData;

my $qd = FrameNet::QueryData->new();

is(ref $qd, 'FrameNet::QueryData', 'Object loading test');
isnt($qd->fnhome, '', 'FNHOME test');
ok($qd->path_related("Communication", "Topic", "Using"));
ok(! $qd->path_related("Communication", "Topic", "Inheritance"));
ok($qd->path_related("Communication", "Intentionally_create", "Using", "Inheritance"), "Path related test");



#print STDERR $qd->frame('Getting')->{'name'};
#is($qd->frame('Getting')->{'name'}, 'Getting', 'Frame data test');
