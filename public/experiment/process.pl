#!/usr/bin/perl
use strict;
use warnings;
use Smart::Comments;
use Geo::Coder::Google;
use JSON;

my @articles;

sub main(){

  # input data
  &load_data( "./unlabeled" );

  for(my $i=0; $i<@articles ; $i++)
  {
    my $article_href = $articles[$i];

    # export to temp folder
    my $tmp = "./tmp";
    my $tmp_file = $tmp . "/0";
    open(TEMP, "> " . $tmp_file) or die $!;
    print TEMP $article_href->{'Title'} . "\n" . $article_href->{'Snippet'} ;
    close(TEMP);

    # classification
    &do_classify($article_href, $tmp);

    # get location
    &get_location($article_href, $tmp_file);

    # output json file
    my $json_text = encode_json $article_href;

    print $json_text."\n";
  }
}

# get location
sub get_location()
{
  my ( $article_href, $tmp_file ) = @_;

  # run stanford ner
  my $cmd = "java -cp ./stanford-ner-2014-10-26/stanford-ner-with-classifier.jar edu.stanford.nlp.ie.NERServer -port 9191 -client < " . $tmp_file ;
  my $result = `$cmd`;

  # process result
  my ($skip, @results) = split('\n', $result);
  my @name_entities = split(' ', join('', @results));

  # count location occurrence
  my %locations;
  my $is_location = 0;
  my $term = "";
  foreach my $name_entity (@name_entities) {
    if( my ($loc) = $name_entity =~ /(.*?)\/LOCATION/ )
    {
      $term = $term . " " . $loc;
      $is_location = 1;
    }
    else
    {
      if($is_location)
      {
        $term =~ s/^ // ;
        $locations{$term} ++ ;
        $term = "";
      }
      $is_location = 0;
    }
  }
  if($is_location)
  {
    $locations{$term} ++ ;
  }
  my @keys = ( sort {$locations{$b} <=> $locations{$a}} (keys (%locations)) );

  # get lat and lng
  if( @keys != 0 )
  {
    # assign
    $article_href->{'Location'} = $keys[0];

    # get lat, lng
    my $geocoder = Geo::Coder::Google->new(apiver => 3);
    my $latlng = $geocoder->geocode(location => $keys[0]);
    $article_href->{'Lat'} = $latlng->{geometry}{location}->{lat};
    $article_href->{'Lng'} = $latlng->{geometry}{location}->{lng};
  }
}

# classification
sub do_classify()
{
  my ( $article_href, $tmp ) = @_;

  # run classifier
  my $cmd = "./Mallet/bin/mallet classify-dir --input " . $tmp . " --output - --classifier ./cdc.classifier";
  my $result = `$cmd` ;
  my ($skip, @results ) = split(' ', $result);

  # process result
  my %relevance_result;
  for(my $i=0 ; $i<(@results) ; $i=$i+2)
  {
    $relevance_result{ $results[$i] } =  sprintf( "%.10f", $results[$i+1] );
  }

  # sort relevance result
  my @keys = ( sort {$relevance_result{$b} <=> $relevance_result{$a}} (keys (%relevance_result)) );

  # assign
  $article_href->{'DiseaseName'} = $keys[0];
  $article_href->{'Relevance'} = $relevance_result{$keys[0]};
}

# load file input memory
sub load_data()
{
  my ($path) = @_;

  # foreach file
  opendir (DIR, $path) or die $!;
  while (my $file = readdir(DIR)) {
    next if ( $file eq '.' || $file eq '..' );

    # load file
    local(*INPUT, $/);
    open(INPUT, $path . "/" . $file) or die $!;
    my $content = <INPUT>;
    my @splitted = split("\n", $content);

    my %article;
    $article{'Title'} = $splitted[0];
    $article{'Snippet'} = $splitted[1];
    $article{'Url'} = $splitted[2];
    $article{'Source'} = $splitted[3];
    $article{'Language'} = $splitted[4];
    $article{'PublishTime'} = { '$date' => $splitted[5] };
    $article{'CrawlTime'} = { '$date' => $splitted[6] };

    # push into array
    push @articles, \%article;
    close(INPUT);
  }
  closedir(DIR);
}

&main;
