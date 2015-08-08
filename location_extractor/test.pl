#!/usr/bin/perl
#
#
use lib "~/lib/perl" ;
use Jperl::Tool::GoogleDict ;

my @a = Jperl::Tool::GoogleDict::gdict("Kim") ;

for(@a){
	print $_ . "\n" ;
}
