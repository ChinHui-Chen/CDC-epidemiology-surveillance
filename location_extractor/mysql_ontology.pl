
sub connectSQL{
		my $db = "project" ;
		my $host = "ir.csie.ntu.edu.tw" ;
		my $user = "project" ;
		my $password = "irlab94" ;

		my $dbh = DBI->connect("DBI:mysql:database=$db;host=$host",
				$user, $password, {RaiseError => 1});
		
		$dbh->do('SET NAMES \'utf8\'');
		
		return $dbh ;
}

sub isTitleExist{
		my $dbh = $_[0] ;
		my $title = $_[1] ;
		my $table = $_[2] ;
		my $col = $_[3] ;

		my $query = sprintf( "SELECT count(*) as num FROM $table WHERE $col=%s" , $dbh->quote($title) ) ;
		my $sth = $dbh->prepare($query);
		$sth->execute();
		my $result = $sth->fetchrow_hashref();
		
		if($result->{num} == 0) {
			return 0 ;
		} else {
			return 1 ;
		}
}
sub mysqlUpdate{
	my $table = $_[0] ;
	my $set = $_[1] ;
	my $where = $_[2] ;
	my $dbh = $_[3] ;

	my $query = "UPDATE $table SET $set WHERE $where" ;
	$dbh->do($query) or die("Can't update") ;

}

1;
