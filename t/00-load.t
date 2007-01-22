#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'FrameNet::QueryData' );
}

diag( "Testing FrameNet::QueryData $FrameNet::QueryData::VERSION, Perl $], $^X" );
