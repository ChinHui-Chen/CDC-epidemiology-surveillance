package IRLAB_Coder ;

# written by Johnson Chen
#
# require Geo::Coder::Yahoo , WebService::Google::Language
# require mysql.pl
#
# location_query (cache!!)

use Geo::Coder::Yahoo ;
use WebService::Google::Language;

# input : a string
# return : a string'
sub translate_google{
		$q = shift ;
		$src = shift ;
		$dest = shift ;

		$service = WebService::Google::Language->new(
				'referer' => 'http://ir.csie.ntu.edu.tw',
				'src'     => $src,
				'dest'    => $dest,
		);

		$result = $service->translate($q);
		if ($result->error) {
				printf "Error code: %s\n", $result->code;
				printf "Message:    %s\n", $result->message;
		}
		else {
				return $result->translation;
		}
}

# input : a location name 
# return : lat \t lngt
sub query_ymap{
		my $loc = shift ;

=c  move to rss_to_db.pl
		# build location mapping
		my $dbh = &connectSQL ;
		my $query = sprintf( "SELECT * FROM location_mapping WHERE location=%s" , $dbh->quote($loc) ) ;
		my $sth = $dbh->prepare($query);
		$sth->execute();

		# load from cache
		if( (my $q = $sth->fetchrow_hashref()) ){
				my $lat = $q->{lat} ;
				my $lng = $q->{lng} ;

				my $result ="";
				$result .= "<lat>".$lat."</lat>" ;
				$result .= "<lng>".$lng."</lng>" ;
				return $result ;

		}else{
		# load from yahoo map
=cut

		$yid = "v6TR7O7V34EdvyrBcsd0YOtWQQoCdS.m8ha3KPkfgs43KpLYfRUW9vwJhATxXfcGvFE-" ;

		my $geocoder = Geo::Coder::Yahoo->new(appid => $yid );
		my $location = $geocoder->geocode( location => $loc );

		$href_ref = $location->[0] ;

		my %hash = %$href_ref ;

		my $result = $hash{'latitude'}."\t".$hash{'longitude'} ;
		return $result ;

=c
		# insert database
		my $query = sprintf( "INSERT INTO location_mapping VALUES( null , %s, %f, %f)" , $dbh->quote($loc) , $hash{'latitude'} , $hash{'longitude'}) ;
		$dbh->do($query) or die("Can't insert into location mapping") ;
=cut

=c return example
	{
			'country' => 'US',
			'longitude' => '-118.3387',
			'state' => 'CA',
			'zip' => '90028',
			'city' => 'LOS ANGELES',
			'latitude' => '34.1016',
			'warning' => 'The exact location could not be found, here is the closest match: Hollywood Blvd At N Highland Ave, Los Angeles, CA 90028',
			'address' => 'HOLLYWOOD BLVD AT N HIGHLAND AVE',
			'precision' => 'address'
	}
=cut
}

1;
