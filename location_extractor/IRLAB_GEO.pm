#! /usr/bin/perl
# Written By JohnsonChen
#
# require : run NEP server first , modify connectSQL function
# input a doc 
# return a list of locations (ranking by my algo)

package IRLAB_GEO ;

use WebService::Google::Language;
use Text::NLP::Stanford::EntityExtract;
use LWP::UserAgent ;
use Text::Iconv ;
use LWP;
use JSON;
use strict ;

sub tw_ner_parser{
		my $query = shift ;

		# UTF8->BIG5
		my $converter = Text::Iconv->new("UTF-8", "BIG5");
		my $query_big5 = $converter->convert($query);

		# POST to sinica ws 
		my $ua = new LWP::UserAgent;
		my $response = $ua->post('http://mt.iis.sinica.edu.tw/cgi-bin/text.cgi' ,
				{ query=>$query_big5 });

		# get tag url
		my ($page) = ($response->content) =~ /\/(\d*?)\.html/ ;
		my $tag_url = "http://mt.iis.sinica.edu.tw/uwextract/pool/$page.tag.txt" ;

		# download url
		my $tag_text = $ua->get( $tag_url ) ;

		# BIG5->UTF8
		$converter = Text::Iconv->new("BIG5", "UTF-8");
		my $tags = $converter->convert($tag_text->content);

		# extract locations
		my %loc ;
		while( $tags =~ /　([^　]*?)\(Nc\)/s ){
				$tags = $' ;
				$loc{$1}++ ;
		}

		my @result ;
		foreach my $key (sort {$loc{$b} <=> $loc{$a} } (keys(%loc))) {
				next if($loc{$key} < 1) ;

				if( &is_tw_location($key) ) {
						push(@result , "$loc{$key} $key" );
				}
					
		}
		undef %loc ;

		return @result ;
}

# filter TC location
sub is_tw_location{ 
		my $key = shift ;


		# if length = 1 , false
		utf8::decode($key) ;
		if( length($key) < 2 ){
			return 0 ;
		}

		# if in list , false
		open(FHD , "stoplist") or die "can't open stoplist" ;
		my @list = <FHD> ;
		foreach(@list){
			chomp ;
			if( $key eq $_ ){
				return 0 ;
			}
		}
		close FHD ;

		# check if in gazateer
		my $key_trans = &dictionary_google($key) ; # done
		my $dbh = connectSQL() ;
		my $query = sprintf( "SELECT count(*) as N , pop FROM gazetteer WHERE en_name=%s OR alt_name LIKE %s" , $dbh->quote($key_trans) , $dbh->quote("%".$key."%") ) ;
		my $sth = $dbh->prepare($query) ;
		$sth->execute ;

		# check exist
		my $href = $sth->fetchrow_hashref ;
		if( $href->{'N'} == 0 ){
			return 0 ;
		}

		# check popularity
		if( $href->{'pop'} < 100000 ){
			return 0 ;
		}

		return 1 ;

}


# NER , use my POS tagging
sub en_ner_parser{
		my $absPath = "/home/irlab94/epidemic/program/loc_extracter" ;
		my $input = 'input' ;
		my %loc ;
		my $pwd ;
		my @input ; 
		$input[0] = shift ;

		# start
		$pwd = `pwd` ;	
		chdir $absPath ;

		my $ner = Text::NLP::Stanford::EntityExtract->new;
		my $server = $ner->server;
		my @tagged_text = $ner->get_entities(@input);
		my $content = join('',@tagged_text) ;

		my $preStr = "" ;

		my @word = split(/[ ><]/, $content);

		for(my $k = 0; $k < $#word; $k ++){
				if($word[$k] =~ /(.*)\/LOCATION/){

						my $location = $1 ;

						if( $k!=0 && $word[$k-1] =~ /\/LOCATION/ ){
								# del pre Str
								$loc{lc($preStr)} = $loc{lc($preStr)}-1 ;

								$preStr = $preStr." ".$location ;

								# add cur Str 
								$loc{lc($preStr)} = $loc{lc($preStr)}+1 ;

						}else{
								$loc{lc($location)} = $loc{lc($location)}+1 ;
								$preStr = $location ;
						}
				}else{
						$preStr="";
				}
		}


		my @result ;
#		my $flag = 0 ;
		foreach my $key (sort {$loc{$b} <=> $loc{$a} } (keys(%loc))) {
				next if($loc{$key} < 1) ;
#				$flag = 1; 
				push(@result , "$loc{$key} $key" );	
		}

		undef %loc ;

		chdir $pwd ;

		return @result ;
}

# NER , use original POS
sub en_ner_parser_normal{
		my $absPath = "/home/irlab94/epidemic/program/loc_extracter" ;
		my %loc ;
		my $pwd ;
		my @input ; 
		$input[0] = shift ;

		# start
		$pwd = `pwd` ;	
		chdir $absPath ;

		my $ner = Text::NLP::Stanford::EntityExtract->new;
		my $server = $ner->server;
		my @tagged_text = $ner->get_entities(@input);
		my $tagged_text = join('',@tagged_text) ;
		$tagged_text .= " " ;
		while( $tagged_text =~ /(.*?)\// ){
				$tagged_text = $' ;
				my $term = $1 ;
				$tagged_text =~ /(.*?) / ;
				$tagged_text = $' ;
				my $POS = $1 ;

				if( $POS eq "LOCATION" ){
						$loc{lc($term)}++ ;
				}
		}

		chdir $pwd ;
		return %loc ;
}

# input : a string
# return : a string'
sub dictionary_google{
		my $q = shift ;

		my $script_name = $0;

		my ($from, $to, $word) = ('zh-TW', 'en', $q);

		foreach(@ARGV) {
				my $param = $_;
				if($param =~ /^--from=(\w+)/) {
						$from = $1;
				}
				elsif($param =~ /^--to=(\w+)/) {
						$to = $1;
				}
				elsif($param =~ /^--version/) {
						print "Perl Google dictionary client version 1.0\n";
						exit(0);
				}
				elsif($param =~ /^--help/) {
						print "usage:\n $script_name [--from=FROM_LANG] [--to=TO_LANG] 'PHRASE'\n";
						exit(0);
				}
				elsif($param =~ /^--/) {
						warn "Bad parameter $param \n usage:\n $script_name [--from=FROM_LANG] [--to=TO_LANG] 'PHRASE'\n";
						exit(0);
				}
				else {
						$word = $param;
				}
		}

		my $ua = LWP::UserAgent->new;
		$ua->agent("PGDict/1.0");

		$word =~ tr/ /+/;

		my $req = HTTP::Request->new(GET => "http://ajax.googleapis.com/ajax/services/language/translate?v=1.0&langpair=$from|$to&q=$word");
		my $res = $ua->request($req);

		if($res->is_success) {
				my $perl_res = from_json($res->content);	
				if($perl_res->{'responseStatus'} eq '200') {
						return $perl_res->{'responseData'}->{'translatedText'};
				}
				else {
						warn "Error ". $perl_res->{'responseDetails'}."\n";
				}
		}
		else {
				# $res->status_line;
		}
}

sub connectSQL{
		my $db = "project" ;
#		my $host = "ir.csie.ntu.edu.tw" ;
		my $host = "localhost" ;
		my $user = "project" ;
		my $password = "irlab94" ;

		my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host",
				$user, $password, {RaiseError => 1});

		$dbh->do('SET NAMES \'utf8\'');

		return $dbh ;
}

1;
