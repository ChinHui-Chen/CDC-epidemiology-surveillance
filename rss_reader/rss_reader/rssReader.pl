#! /usr/bin/perl
# Writed by JohnsonChen
#
# local configure 
use File::Path;
use URI::Escape;

$myget = "../lib/myget.php" ;

$abs_dir = "/home/student/94/b94095/epidemic/" ;

$data_dir = "../data/" ;
$rss_data_dir = $data_dir."rss_raw/" ;
$raw_name = "rss-raw-" ;

$rseed = "./urls" ;
$rssed_temp = "temp.xml" ;

$save_file = "./save.sv" ;

$bufferSize = 50 ;
#
# Code start
while(1){
print "Run !\n"; 
# Load state
open( LS , $save_file ) ;
while( <LS> ){
	($key , $value) = split(/\$/);
	next if($key eq "" || $value eq "") ;
	$memory{$key} = $value ;
}
close(LS) ;

# load state ok , ready to start
open(FH , $rseed) ;

while( <FH> ){
	$url = $_ ;

	# for comment
	$chr = substr $url , 0 , 1;
	if( $chr eq "/" ){
		next ;
	}
	$url =~ s/\n//g ;
	next if($url eq "") ;

	if($url =~ /(.*?)\$(.*)/ ){
		$media_dir = $1; 
		$url = $2 ;
	}else{
		print "Url without dirname\n" ;
		next ;
	}


	# Download rss page
	print "Download ... $url " ;
	$url =~ s/\&/\\\&/g ;
	#$com = "php ".$myget." ".$url." >".$abs_dir."rss_reader/".$rssed_temp ;
	$com = "wget -O ".$rssed_temp." -t2 -l2 -E -e robots=off - -awGet.log -T 200 -H -Priserless -U \"Mozilla/5.0 (Windows; U; Windows NT5.1; en-US; rv:1.7) Gecko/20040613 Firefox/0.8.0+\" $url" ;
	
	$a = system($com) ;
	if($a != 0){
		print "Error! \n" ;
		next ;
	}
	# For each rss seed
	open(FP , $rssed_temp) or die("can't open rssed_temp") ;
	@content = <FP> ;
	$content = join('',@content) ;

	#if rss
	$rss_content = &xml_parser( $content , "channel" ) ;
	$media = &xml_parser($rss_content , "title") ;
	$pubDate = &xml_parser($rss_content , "pubDate") ;
	$language = &xml_parser($rss_content , "language") ;		
	$sourceLink = $url ;

	if  ($media eq "NULL"){
		print " NULL \n" ;
		next ;
	}

	# if not GoogleNews, Check uptodate date
	if( $memory{$media} eq $pubDate."\n" ){
		print " Up-to-date !!\n" ;
		next ;
	}else{
		print "\n" ;
		$memory{$media} = $pubDate ;
	}

	# Mkdir & Find Current process
	
	#$media_dir = uri_escape($media) ;
	&makedir( $rss_data_dir.$media_dir );

	# Find Current Processed Num
	open( FD , $rss_data_dir.$media_dir."/update.ini" ) ;
	while( <FD> ){
		($key , $value) = split(/\$/);
		next if($key eq "" || $value eq "") ;
		$value =~ s/\n//g ;
		$hash{$key} = $value ;
	}
	close(FD) ;

	if(defined($hash{'current'})){
		$current_num = $hash{'current'} ;
	} else {
		$current_num = 0 ;
	}

	if(defined($hash{'currentPtr'})){
		$currentPtr = $hash{'currentPtr'} ;
	}else{
		$currentPtr = 0;
	}
	
	# Loop for each item
	while( $rss_content =~ /<item>(.*?)<\/item>/s ){
		$rss_content = $' ;

		$item = $1 ;
		# If Google, Check item for up-to-date
		$title = &xml_parser($item , "title"); 
		if( $media =~ /Google/s ) {
			# For Save Name
			$title = uri_escape($title) ;	

			if( &searchTopic($title) ){
				next ;
			}else{
				print $title." is added $currentPtr\n" ;
				$currentPtr = &addTopic($title,$currentPtr);
			}	
		}
		# Write file 
		$filename = "> ".$rss_data_dir.$media_dir."/".$raw_name.$current_num.".xml" ;
		open( WD , $filename ) ;
	        print WD "<media>$media<\/media>\n<language>$language<\/language>\n<sourceLink>$sourceLink<\/sourceLink>".$item;
		close(WD) ;

		$current_num++ ;
	}
	closedir(RSSDIR) ;

	# Save state
	$hash{'current'} = $current_num ;
	$hash{'currentPtr'} = $currentPtr ;
	open(SS,">".$rss_data_dir.$media_dir."/update.ini") ;
	while (my ($key, $value) = each (%hash)) {
		next if($key eq "" || $value eq "") ;
		print SS $key."\$".$value."\n" ; 
	}
	close(SS) ;

	undef %hash; 
}

# Save state
open(SS,">".$save_file) ;
while (my ($key, $value) = each (%memory)) {
	next if($key eq "" || $value eq "") ;
	print SS $key."\$".$value."\n" ; 
}
close(SS) ;

undef %memory ;

sleep(1800) ;

# end of infinity loop
}


# function for xml_parser
sub xml_parser{
	$content = $_[0] ;
	$pattern = $_[1] ;

	if( $content =~ /<$pattern>(.*?)<\/$pattern>/s ){
		return $1 ;
	}else{
		return NULL ;
	}
}

# function create dir
sub makedir{
	$DIR = $_[0] ;
	if(! -d "$DIR"){
		mkpath("$DIR") || die("Could not create directory");
	}
}

# function search
sub searchTopic{
	$s = $_[0] ;

	for($k=0 ; $k<$bufferSize; $k++){
		if( $hash{$k} eq $s ) {
			return 1 ;
		} 
	}
	return 0 ;
}

# function add
sub addTopic{
	$s = $_[0] ;
	$num = $_[1] ;

	$hash{$num} = $s ;

	$num ++ ;
	# For circle
	if($num==$bufferSize){
		$num = 0 ;	
	}
	return $num ;
}

# function display
sub showHash{
	for($k=0;$k<$bufferSize;$k++){
		print $k." ".$hash{$k}."\n" ; 
	} 
}
