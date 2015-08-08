
sub loadFile{
	$path = $_[0] ;
	open(FH , $path) ;
	my @itemAll = <FH> ;
	my $itemAll = join('',@itemAll) ;
	close(FH);	

	return $itemAll ;
}

# function create dir
sub makedir{
		my $DIR = $_[0] ;
		if(! -d "$DIR"){
				mkpath("$DIR") || die("Could not create directory");
		}
}

sub is_dir{
	if ( -d $_[0] ) { return 1; } else { return 0; }
}

1;
