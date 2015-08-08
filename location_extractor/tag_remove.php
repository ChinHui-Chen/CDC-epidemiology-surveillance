#!/usr/local/bin/php -q

<?
$text=trim(fgets(STDIN,4096));
print strip_tags($text);
?>
