
sub remove_html_tag{
		my $content = $_[0] ;
		
		#$content =~ s/\(//gs ;
		#$content =~ s/\)//gs ;
		#$content =~ s/<(?:[^>'"]*|(['"]).*?\1)*>//gs ;
		$content =~ s/<[^>]*>//gs;
		$content =~ s///gs ;

		return $content ;
}
sub html_decode{
		my $content = $_[0] ;
		$content = HTML::Entities::decode($content) ;
		return $content ;
}
sub myIconv{
		my $encode = $_[0] ;
		my $content = $_[1] ;

		my $converter ;

		print "Convert $encode to utf8\n" ;

		if($encode eq "UTF-8"){
				return $content ;
		}

		$converter = Text::Iconv->new($encode,"UTF-8") ;
		$content = $converter->convert($content) ;
		return $content ;
}
sub trim{
		my $temp = $_[0] ;
		$temp =~ s/^\s+//;
		$temp =~ s/\s+$//;

		return $temp ;
}


1;
