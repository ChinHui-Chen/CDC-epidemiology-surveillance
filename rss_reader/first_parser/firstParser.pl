#!/usr/bin/perl
# Writed by JohnsonChen
#
# import
use strict ;
use File::Path;
use HTML::Entities;
use Text::Iconv ;

#
# Local configure
my $myget = "../lib/myget.php" ;

my $abs_dir = "/home/student/94/b94095/epidemic/" ;

my $data_dir = "../data/" ;
my $rss_raw_dir = $data_dir."rss_raw/" ;
my $rss_text_dir = $data_dir."rss_text/" ;

my $temp_htm = "temp.htm" ;

my $rss_raw_name = "rss-raw-" ;
my $rss_text_name = "rss-text-" ;

while(1){
#
# Open rss_raw 's dir
opendir(RAWDIR , $rss_raw_dir) ;
my @rawDir = sort readdir(RAWDIR) ;
my $totalDir = @rawDir -2 ;
closedir(RAWDIR) ;

for(my $i=0;$i<$totalDir;$i++ ){
	my $path = $rss_raw_dir.$rawDir[$i+2] ;
	my $savePath = $rss_text_dir.$rawDir[$i+2] ;
	# Make dir
	&makedir($savePath) ;
	# Check dir
	if( !is_dir($path) ){
		next ;
	}

	# Load file
	my %memory ;
	open(FD , $savePath."/parser.ini") ;
	while(<FD>){
		(my $key , my $value) = split(/\$/) ;
		$value =~ s/\n//s ;
		$memory{$key} = $value ;
	}
	close(FD);
	
	my $curParsed ;
	my $toBeSaved ;
	if(defined($memory{'curParsed'})){
		$curParsed = $memory{'curParsed'} ;
	}else{
		$curParsed = 0 ;
	}	
	if(defined($memory{'toBeSaved'})){
		$toBeSaved = $memory{'toBeSaved'} ;
	}else{
		$toBeSaved = 0 ;
	}	

	# Load total num of xml
	my $totalXml ;
	open(FD , $path."/update.ini") ;
	while(<FD>){
		(my $key , my $value) = split(/\$/) ;
		$value =~ s/\n//s ;
		if($key eq "current"){
			$totalXml = $value ;
		}
	}
	close(FD);

	print $path."\n" ;

	# Code start
	if( $curParsed == $totalXml ){
		next ;
	}

	for( ;$curParsed<$totalXml;$curParsed++){
		print $curParsed." ".$toBeSaved." ".$totalXml."\n" ;
		# Open xml
		open(FD,$path."/".$rss_raw_name.$curParsed.".xml") or die("can't open") ;
		my @content = <FD> ; my $content = join('',@content) ;
		my $raw_content = "" ; # use for rss_text
		close(FD) ;

		# For raw_content
		if( $content =~ /<media>(.*?)<\/media>/s ){
			$raw_content .= "<media>$1<\/media>\n" ;}
		if( $content =~ /<language>(.*?)<\/language>/s ){
			$raw_content .= "<language>$1<\/language>\n" ;}
		if( $content =~ /<sourceLink>(.*?)<\/sourceLink>/s ){
			$raw_content .= "<sourceLink>$1<\/sourceLink>\n" ;}
		if( $content =~ /<title>(.*?)<\/title>/s ){
			$raw_content .= "<title>$1<\/title>\n" ;}
		if( $content =~ /<description>(.*?)<\/description>/s ){
			$raw_content .= "<description>$1<\/description>\n" ;}
		if( $content =~ /<link>(.*?)<\/link>/s ){
			$raw_content .= "<link>$1<\/link>\n" ;}
		if( $content =~ /<pubDate>(.*?)<\/pubDate>/s ){
			$raw_content .= "<pubDate>$1<\/pubDate>\n" ;}
		if( $content =~ /<category>(.*?)<\/category>/s ){
			$raw_content .= "<category>$1<\/category>\n" ;}

		
		# Parse Info	
		my $link ;
		my $media ;
		if( $content =~ /<link>(.*?)<\/link>/s ){
			$link = $1 ;
		}
		if( $content =~ /<media>(.*?)<\/media>/s ){
			$media = $1 ;
		}

		my $text ;
		
		if($media =~ /Google/s) {
			$text = &google_parser($content) ;	
		} else {

		print "myget $link ..." ;
		# Download link		
		$link =~ s/\&/\\\&/g ; # should we encode ?
		# my $com = "php ".$myget." ".$link." >".$abs_dir."first_parser/".$temp_htm ;
		my $com = "wget -O temp.htm -t2 -l2 -E -e robots=off - -awGet.log -T 200 -H -Priserless -U \"Mozilla/5.0 (Windows; U; Windows NT5.1; en-US; rv:1.7) Gecko/20040613 Firefox/0.8.0+\" $link" ;
		$a = system($com) ;
		if($a != 0){
			print " Error!\n" ;
			# Link Error
			open(FF , ">".$savePath."/".$rss_text_name.$toBeSaved.".xml") ;
			$raw_content .= "<ir-text>link unavailable<\/ir-text>\n" ;
			print FF $raw_content ;
			close(FF) ;
		
			$toBeSaved++ ;	
			
			next ;
		}
		print " Ok!\n" ;

		# Open Link		
		open(FD,"./".$temp_htm) ;
		my @htm_content = <FD> ;
		my $htm_content = join('',@htm_content) ;
		close(FD) ;

		# Convert charset
		$htm_content = &convert_charset($htm_content) ;
			
		# Classified media
		if( $media =~ /CNN\.com/ ){
			$text = &cnn_parser($htm_content) ;
			$text = &XML_Writer($text) ;	
		} elsif( $media =~ /BBC News/ ){
			$text = &bbc_parser($htm_content) ;
			$text = &XML_Writer($text) ;	
		} elsif( $media =~ /ABC News/ ){
			$text = &abc_parser($htm_content) ;
			$text = &XML_Writer($text) ;	
		} elsif( $media =~ /U\.S\. News/ ){
			$text = &us_parser($htm_content) ;
			$text = &XML_Writer($text) ;	
		} elsif( $media =~ /中時電子報/ ){
			$text = &chinatimes_parser($htm_content ) ;
			$text = &XML_Writer($text) ;	
		} elsif( $media =~ /Yahoo!奇摩新聞/ ){
			$text = &yahootw_parser($htm_content) ;	
			$text = &XML_Writer($text) ;	
		} elsif( $media =~ /Google/ ) {
			$text = &google_parser($htm_content) ;	
		}
	
		}
		# Save text xml
		open(FF , ">".$savePath."/".$rss_text_name.$toBeSaved.".xml") ;
		$raw_content =~ s///gs ;	
		$raw_content .= "\n<ir_text>".$text."<\/ir_text>\n" ;
		
		$raw_content = "<epidemic>\n".$raw_content."\n</epidemic>" ;

		print FF $raw_content ;
		close(FF) ;
	
		$toBeSaved++ ;
	}

	# Save file	
	$memory{'toBeSaved'} = $toBeSaved ;
	$memory{'curParsed'} = $curParsed ;
	open(FD,">".$savePath."/parser.ini") ;
	while (my ($key, $value) = each (%memory)) {
		next if($key eq "" || $value eq "") ;
		print FD $key."\$".$value."\n" ; 
	}
	close(FD) ;
	undef %memory ;
}
	
	print "done\n" ;
# end of the infinity loop
sleep(1800) ;
}

sub XML_Writer{
	my $content = $_[0] ;
	$content =~ s/\&/&amp;/gs ;
	$content =~ s/</&lt;/gs ;
	$content =~ s/>/&gt;/gs ;
	$content =~ s/'/&apos;/gs ;
	$content =~ s/"/&quot;/gs ;
	return $content ;
}

#
sub google_parser{
	my $htm_content = @_[0] ;
	my $content = "" ;

	$htm_content =~ /<description>(.*?)<\/description>/s ;
	my $desc = HTML::Entities::decode($1); 

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

			# For XML special char
			$itemTitle = &XML_Writer($itemTitle) ;	
			$itemLink =  &XML_Writer($itemLink) ;
			$itemMedia = &XML_Writer($itemMedia) ;
			$itemRtime = &XML_Writer($itemRtime) ;
			$itemDesc =  &XML_Writer($itemDesc) ;

			$item .= "<item><itemTitle>$itemTitle</itemTitle><itemLink>$itemLink</itemLink><itemMedia>$itemMedia</itemMedia><itemRtime>$itemRtime</itemRtime><itemDesc>$itemDesc</itemDesc></item>\n" ;
		}

		# Find all item
		$content = $item ;	
	} else { # if not , is possible
		$content = "" ;	
	}
	return $content ;
}
		
sub yahootw_parser{
	my $htm_content = @_[0] ;
	my $content = "" ;
	
	while( $htm_content =~ /<!--\(begin\) inc-article_content.jake -->(.*?)<!--\(end\) inc-article_content.jake -->/s ){
		$htm_content = $' ;
		$content .= $1."\n" ;
	}
	if ( $content =~ /<div id="ynwsartcontent">(.*?)<\/div>/s ){
		$content = $1 ;
	}
	$content =~ s/<\/p>/\n/g ;

	# remove html tag
	$content = &remove_html_tag($content) ;

	return $content ;
}

sub chinatimes_parser{
	my $htm_content = @_[0] ;
	my $content = "" ;
	
	while( $htm_content =~ /<!--content begin-->(.*?)<!--content end-->/s ){
		$htm_content = $' ;
		$content .= $1."\n" ;
	}
	$content =~ s/&nbsp;//g ;

	# remove html tag
	$content = &remove_html_tag($content) ;
	
	return $content ;
}
sub us_parser{
	my $htm_content = @_[0] ;
	my $content = "" ;

	$htm_content =~ s/<ul id="pagination-list">.*//s ;

	while( $htm_content =~ /<p *>(.*?)<\/p>/s ){
		$htm_content = $';
		$content .= $1."\n" ;
	}
	# remove html tag
	$content = &remove_html_tag($content) ;
	# convert &bnsp to space
	$content = &html_decode($content) ;

	return $content ;
}

sub abc_parser{
	my $htm_content = @_[0] ;
	my $content = "" ;

	$htm_content =~ s/<div id="community-options".*//s ;

	while( $htm_content =~ /<p *>(.*?)<\/p>/s ){
		$htm_content = $';
		$content .= $1."\n" ;
	}
	# remove html tag
	$content = &remove_html_tag($content) ;
	# convert &bnsp to space
	$content = &html_decode($content) ;

	return $content ;
}

sub bbc_parser{
	my $htm_content = @_[0] ;
	my $content = "" ;
	
	while( $htm_content =~ /<!-- S BO -->(.*?)<!-- E BO -->/s ){
		$htm_content = $' ;	
		$content .= $1."\n" ;
	}

	# remove image descript
	$content =~ s/<!-- S IIMA -->.*?<!-- E IIMA -->//gs ;
	# remove html tag
	$content = &remove_html_tag($content) ;
	# convert &bnsp to space
	$content = &html_decode($content) ;

	return $content ;
}

sub cnn_parser{
	my $htm_content = @_[0] ;

	my $content = "" ;
	while( $htm_content =~ /<p *>(.*?)<\/p>/s ){
		$htm_content = $' ;	
		$content .= $1."\n" ;
	}
	
	# remove image descript
	$content =~ s/<\!--===========CAPTION==========-->.*?<!--===========\/CAPTION=========-->//gs ;
	# remove html tag
	$content = &remove_html_tag($content) ;
	# convert &bnsp to space
	$content = &html_decode($content) ;
	
	return $content ;
}


sub remove_html_tag{
	my $content = @_[0] ;
	$content =~ s/<.*?>//gs ;
	$content =~ s///gs ;
	return $content ;
}


sub html_decode{
	my $content = @_[0] ;
	$content = HTML::Entities::decode($content) ;
	return $content ;
}

sub convert_charset{
	my $temp = @_[0] ;
	if( $temp =~ /<meta.*?charset=(.*?)>/i ){
		my $converter ;
		if( $1 =~ /big5/i ){
			$converter = Text::Iconv->new("BIG5","UTF-8") ;
			$temp = $converter->convert($temp) ;
		}elsif( $1 =~ /iso-8859-1/i ){
			$converter = Text::Iconv->new("ISO-8859-1","UTF-8") ;
			$temp = $converter->convert($temp) ;
		}
		
	}

	return $temp ;
	
}

sub is_dir{
	if ( -d $_[0] ) { return 1; } else { return 0; }
}

sub makedir{
	my $DIR = $_[0] ;
	if(! -d "$DIR"){
		mkpath("$DIR") || die("Could not create directory");
	}
}
