# function for xml_parser
sub xml_parser{
		my $content = $_[0] ;
		my $pattern = $_[1] ;

		if( $content =~ /<$pattern>(.*?)<\/$pattern>/s ){
				return $1 ;
		}else{
				return "NULL" ;
		}
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

1;
