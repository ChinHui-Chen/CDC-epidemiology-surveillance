#!/usr/bin/perl

$meteor_url = `meteor mongo --url cdcproject.meteor.com`;

($user, $pwd, $host, $port, $db) = $meteor_url =~ /mongodb:\/\/(.*?):(.*?)@(.*?):(.*?)\/(.*)\n/s;

$import_cmd = "mongoimport --host " . $host . " --port " . $port . " --username " . $user . " --password " . $pwd . " --db " . $db . " --collection articles --file ./demo.json" ;

`$import_cmd`;
