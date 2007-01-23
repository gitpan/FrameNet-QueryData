#!perl -T

use Test::More tests => 3;
use FrameNet::QueryData;

my $qd = FrameNet::QueryData->new('-cache' => 1);

ok($qd->path_related("Communication", "Topic", "Using"), 
   "Communication -> Using -> Topic");
ok(! $qd->path_related("Communication", "Topic", "Inheritance"),
   "! Communication -> Inheritance -> Topic");
ok($qd->path_related("Communication", "Intentionally_create", "Using", "Inheritance"),
   "Communication -> Using -> Inheritance -> Intentionally_create");


