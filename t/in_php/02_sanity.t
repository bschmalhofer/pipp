<?php

# Sanity of Test.php

require_once 'Test.php';

plan( 6 );

ok(42, 'fortytwo');

nok(0, 'zero');

is('a', 'a', 'a is a');

isnt('a', 'b', "a isn't b");

like('abcd', '/\w{4}/', "match");

unlike('abcd', '/\w{5}/', "no match");

# vim: expandtab shiftwidth=4 ft=php:
?>
