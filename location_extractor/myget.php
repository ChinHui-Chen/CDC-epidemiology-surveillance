<?
	require_once 'Zend/Http/Client.php';

	$url =  $argv[1]; 
	
	$client = new Zend_Http_Client($url, array(
				'maxredirects' => 0,
				'timeout'      => 30));

	$response = $client->request();


	$ctype = $response->getHeader('Content-type');
	if (is_array($ctype)) $ctype = $ctype[0];

	$body = $response->getBody();
	if ($ctype == 'text/html' || $ctype == 'text/xml') {
		$body = htmlentities($body);
	}

	$body = html_entity_decode($body , ENT_COMPAT , "UTF-8") ;

	echo $body ;
?>
