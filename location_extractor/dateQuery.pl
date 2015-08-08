
#!/usr/bin/perl
use POSIX;

	$time = mktime(30,0,1,30,9-1,2008-1900) ;
	print &timeQuery( $time , 2008 , 10 , 1 , 0 ) ;





sub timeQuery{
	$timestamp = $_[0] ;
	$year = $_[1] ;
	$mon = $_[2] ;
	$mday = $_[3] ;
	$hour = $_[4] ;

	$base = mktime( 0, 0, $hour , $mday , $mon-1 , $year-1900 ) ;
	$diff = $timestamp - $base ;
	if($hour == 0){ 
		if( $diff < 86400 && $diff >=0 ){
			return 1;
		}
	}else{
		if( $diff < 3600 && $diff >=0 ){
			return 1;
		}
	}
	return 0 ;
}


