<?php

# Sanity of Test.php

require_once 'Test.php';

plan( 6 );
$count = 1;

ok(42, 'fortytwo', $count);
$count++;

nok(0, 'zero', $count);
$count++;

is('a', 'a', 'a is a', $count);
$count++;

isnt('a', 'b', "a isn't b", $count);
$count++;

like('abcd', '/\w{4}/', "match", $count);
$count++;

unlike('abcd', '/\w{5}/', "no match", $count);
$count++;

# vim: expandtab shiftwidth=4 ft=php:
?>
