
sub cnn_parser{
	my $htm_content = $_[0] ;

	my $content = "" ;
	while( $htm_content =~ /<p *>(.*?)<\/p>/s ){
		$htm_content = $' ;	
		$content .= $1."\n" ;
	}
	
	# remove image descript
	$content =~ s/<\!--===========CAPTION==========-->.*?<!--===========\/CAPTION=========-->//gs ;

	$content = &cleanContent($content) ;
	
	return $content ;
}
sub bbc_parser{
	my $htm_content = $_[0] ;
	my $content = "" ;
	
	while( $htm_content =~ /<!-- S BO -->(.*?)<!-- E BO -->/s ){
		$htm_content = $' ;	
		$content .= $1."\n" ;
	}

	# remove image descript
	$content =~ s/<!-- S IIMA -->.*?<!-- E IIMA -->//gs ;

	$content = &cleanContent($content) ;

	return $content ;
}
sub abc_parser{
	my $htm_content = $_[0] ;
	my $content = "" ;

	$htm_content =~ s/<div id="community-options".*//s ;

	while( $htm_content =~ /<p *>(.*?)<\/p>/s ){
		$htm_content = $';
		$content .= $1."\n" ;
	}

	$content = &cleanContent($content) ;

	return $content ;
}
sub us_parser{
	my $htm_content = $_[0] ;
	my $content = "" ;

	$htm_content =~ s/<ul id="pagination-list">.*//s ;

	while( $htm_content =~ /<p *>(.*?)<\/p>/s ){
		$htm_content = $';
		$content .= $1."\n" ;
	}

	$content = &cleanContent($content) ;

	return $content ;
}
sub chinatimes_parser{
	my $htm_content = $_[0] ;
	my $content = "" ;
	
	while( $htm_content =~ /<!--content begin-->(.*?)<!--content end-->/s ){
		$htm_content = $' ;
		$content .= $1."\n" ;
	}

	$content = &cleanContent($content) ;
	
	return $content ;
}
sub yahootw_parser{
	my $htm_content = $_[0] ;
	my $content = "" ;

	while( $htm_content =~ /<!--\(begin\) inc-article_content.jake -->(.*?)<!--\(end\) inc-article_content.jake -->/s ){
		$htm_content = $' ;
		$content .= $1."\n" ;
	}
	if ( $content =~ /<div id="ynwsartcontent">(.*?)<\/div>/s ){
		$content = $1 ;
	}
	$content =~ s/<\/p>/\n/g ;

	$content = &cleanContent($content) ;

	return $content ;
}
sub google_parser{
		my $desc = $_[0] ;
		my $content = "" ;

		# Decode desc
		$desc = HTML::Entities::decode($desc) ;

		# If find "all news articles"
		if( $desc =~ /<a class=p href="?(.*?)"?>.*?news articles.*?<\/a>/s ) {
				my $allUrl = $1;
				if( &myget("temp.htm" , $allUrl) ==0 ){
						print "Can't download\n" ;
						return ;
				}
				my $itemAll = &loadFile("temp.htm") ;

				# For each item
				my $item = "" ;
				while( $itemAll =~ /<div class=lh>(.*?)<\/div>/s){
						$itemAll = $' ;
						my $itemContent = $1 ;

						$itemContent =~ /<a href="(.*?)".*?>(.*?)<\/a>/s ;
						my $itemLink = $1 ;
						my $itemTitle = $2 ;
						$itemContent = $' ;

						$itemContent =~ /(.*?)<nobr>(.*?)<\/nobr><\/font>(.*?)<\/font>/s ;
						my $itemMedia = $1 ;
						my $itemRtime = $2 ;
						my $itemDesc =  $3 ;

						$itemTitle =~ s/\&#39;/\'/gs ;
						$itemTitle =~ s/\&quot;/\"/gs ;
						$itemDesc =~ s/\&#39;/\'/gs;
						$itemDesc =~ s/\&quot;/\"/gs ;
						
						$itemTitle = &remove_html_tag($itemTitle) ;
						$itemDesc = &remove_html_tag($itemDesc) ;

						#$item .= "$itemTitle\n$itemDesc\n\n" ;
						$item .= $itemDesc."\n\n" ;
				}

				$content = $item ;	
		} else { # If not find
				my $itemTitle = &xml_parser( $htm_content , "title" ) ;
				my $itemLink = &xml_parser( $htm_content , "link" ) ;
				my $itemRtime = &xml_parser( $htm_content , "pubDate" ) ;

				$desc =~ /.*<br>(.*?)<nobr>.*?<\/nobr><\/font>(.*?)<\/font>/s ;
				my $itemMedia = $1 ;
				my $itemDesc = $2 ;

				$itemTitle =~ s/\&#39;/\'/gs ;
				$itemTitle =~ s/\&quot;/\"/gs ;
				$itemDesc =~ s/\&#39;/\'/gs;
				$itemDesc =~ s/\&quot;/\"/gs ;
			
				$itemTitle = &remove_html_tag($itemTitle) ;
				$itemDesc = &remove_html_tag($itemDesc) ;

				#$item .= "$itemTitle\n$itemDesc\n\n" ;
				my $item = "$itemDesc\n\n" ;

				$content = $item ;
		}
		return $content ;
}

sub cnReuterParser{
	my $content = $_[0] ;

	# Parse
	if($content =~ /<span id=\"midArticle_start\"><\/span>(.*?)<p id=\"copyrightNotice\" class=\"copyright\">/s ){
		$content = $1 ;
	}

	# Clean
	$content = &cleanContent($content) ;

	return $content ;
}

sub enReuterParser{
	my $content = $_[0] ;
	
	$content = &cnReuterParser($content) ;

	return $content ;
}

sub cnBaiduParser{
	my $content = $_[0] ;
	
	$content = &cleanContent($content) ;

	return $content ;
}

sub cleanContent{
	my $content = $_[0];

	$content = &remove_html_tag($content) ;
#	$content = &html_decode($content) ;

	return $content ;
}

sub convert_charset{
		my $content = $_[0] ;

		if( $content =~ /charset=(.*?)"/i ){
				my $encode = $1 ;
			
				# conver $content to UTF-8 ;
				$content = encode("utf8",decode($encode,$content)) ;
		} else{
				print "No metadata !\n" ;
		}

		return $content ;
}


sub timeParser{
		my $time = $_[0] ;

		# $time = "Wed, 08 Oct 2008 15:03:13 GMT" ;
		# Wed, 08 Oct 2008 15:03:13 GMT
		# Thu, 09 Oct 2008 14:21:47 EDT	
		my $timestamp = $time ;
		if( $time =~ /([A-Za-z]+), (\d+) ([A-Za-z]+) (\d+) (\d+):(\d+):(\d+)/ ){
				$time = $' ;
				my $mday = int($2) ;
				my $mon = &monConveter($3) ;
				my $year = int($4) ;
				my $hour = int($5) ;
				my $min = int($6) ;
				my $sec = int($7) ;

				if($time =~ /EDT/i){
						$hour = $hour + 4;
				}
				if($time =~ /EST/i){
						$hour = $hour - 5 ;
				}
				$timestamp = mktime( $sec, $min, $hour, $mday, $mon-1, $year-1900 );
		}else{
				print "Can't convert time or already timestamp\n" ;
		}

		return $timestamp ;

}

sub monConveter{
		my $mon = $_[0] ;

		if($mon eq "Jan"){
				return 1 ;
		}
		if($mon eq "Feb"){
				return 2 ;
		}
		if($mon eq "Mar"){
				return 3 ;
		}
		if($mon eq "Apr"){
				return 4 ;
		}
		if($mon eq "May"){
				return 5 ;
		}
		if($mon eq "Jun"){
				return 6 ;
		}
		if($mon eq "Jul"){
				return 7 ;
		}
		if($mon eq "Aug"){
				return 8 ;
		}
		if($mon eq "Sep" || $mon eq "Sept"){
				return 9 ;
		}
		if($mon eq "Oct"){
				return 10 ;
		}
		if($mon eq "Nov"){
				return 11 ;
		}
		if($mon eq "Dec"){
				return 12 ;
		}

		return 1 ;
}

1;
