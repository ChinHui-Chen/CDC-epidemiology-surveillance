#! /usr/bin/perl
#
use strict ;
use HTML::Entities ();

open(FH , "rss-text-2.xml") ;
my @con = <FH> ;
my $con = join('',@con) ;
close(FH) ;

$con = &google_parser($con) ;

print $con."\n" ;

sub google_parser{
	my $htm_content = @_[0] ;
	my $content = "" ;

	$htm_content =~ /<description>(.*?)<\/description>/s ;
	my $desc = HTML::Entities::decode($1); 

	return $desc ;

	# if find all news articles
	if( $desc =~ /<a class=p href="?(.*?)"?>.*?news articles.*?<\/a>/s ) {
		my $allArticleiUrl = $1;
		# Download all article ;
		$allArticleiUrl =~ s/\&/\\\&/g ; 
		my $com = "wget -O temp.htm -t2 -l2 -E -e robots=off - -awGet.log -T 200 -H -Priserless -U \"Mozilla/5.0 (Windows; U; Windows NT5.1; en-US; rv:1.7) Gecko/20040613 Firefox/0.8.0+\" $allArticleiUrl" ;
		system($com) ;

		open(FH , "temp.htm") ;
		my @itemAll = <FH> ;
		my $itemAll = join('',@itemAll) ;
		close(FH);		

		# For each item
		my $item = "" ;
		while( $itemAll =~ /<div class=lh>(.*?)<\/div>/s){
			my $itemContent = $1 ;
			$itemAll = $' ;
			
			$itemContent =~ /<a href="(.*?)".*?>(.*?)<\/a>/s ;
			my $itemLink = $1 ;
			my $itemTitle = $2 ;
			$itemContent = $' ;

			$itemContent =~ /(.*?)<nobr>(.*?)<\/nobr>(.*)/s ;
			my $itemMedia = $1 ;
			my $itemRtime = $2 ;
			my $itemDesc =  $3 ;

			$itemMedia =~ s/<[^>]*>//gs; 
			$itemDesc =~ s/<[^>]*>//gs;

			$item .= "<item><itemTitle>$itemTitle</itemTitle><itemLink>$itemLink</itemLink><itemMedia>$itemMedia</itemMedia><itemRtime>$itemRtime</itemRtime><itemDesc>$itemDesc</itemDesc></item>\n" ;
		}

		# Find all item
		$content = $item ;	
	} else { # if not
		$content = "" ;	
	}
		
	return $content ;
}
