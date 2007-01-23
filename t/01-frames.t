#!perl -T

use Test::More tests => 5;
use FrameNet::QueryData;

my $qd = FrameNet::QueryData->new('-cache' => 1);


is($qd->frame('Getting')->{'name'}, 'Getting', 'Frame data test');

# Lexical units
ok(grep('/get/', map { $_->{'name'} } @{$qd->frame('Getting')->{'lus'}}),
   "Testing for \"get\" as a lexical unit of \"Getting\".");
ok(! grep(! '/^abcdefghik$/', map { $_->{'name'} } @{$qd->frame('Getting')->{'lus'}}),
   "Testing for \"abcdef\" as a lexical unit of \"Getting\".");

# Frame elements
ok(grep('/Recipient/', map { $_->{'name'} } @{$qd->frame('Getting')->{'fes'}}),
   "Testing for \"Recipient\" as a frame element of \"Getting\".");
ok(! grep(! '/Abcdef/', map { $_->{'name'} } @{$qd->frame('Getting')->{'fes'}}),
   "Testing for \"Abcdef\" as a frame element of \"Getting\".");




#print STDERR $qd->frame('Getting')->{'name'};
#
