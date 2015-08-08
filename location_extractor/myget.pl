sub myget{
	my $save = $_[0] ;
	my $link = $_[1] ;
	
	$link =~ s/\&/\\\&/g ; 

	my $com = "wget -O $save -t2 -l2 -E -e robots=off - -awGet.log -T 200 -H -Priserless -U \"Mozilla/5.0 (Windows; U; Windows NT5.1; en-US; rv:1.7) Gecko/20040613 Firefox/0.8.0+\" $link" ;
	$result = system($com) ;

	if($result != 0){
		return 0 ;
	}
	return 1 ;

}
1; 
