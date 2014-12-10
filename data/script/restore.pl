#!/usr/bin/perl

# -h = host, -d = database name, -o = dump folder name
$dump_cmd = "mongodump -h 127.0.0.1:3001 -d meteor -o meteor";
`$dump_cmd`;

$meteor_url = `meteor mongo --url cdcproject.meteor.com`;
($user, $pwd, $host, $port, $db) = $meteor_url =~ /mongodb:\/\/(.*?):(.*?)@(.*?):(.*?)\/(.*)\n/s;

# -h = host, -d = database name (app domain), -p = password, folder = the path to the dumped db
# mongorestore -u client -h c0.meteor.m0.mongolayer.com:27017 -d myapp_meteor_com -p 'password' folder/
$import_cmd = "mongorestore --host " . $host .
                          " --port " . $port .
                          " --username " . $user .
                          " --password " . $pwd .
                          " --db " . $db . " meteor/meteor";
`$import_cmd`;

