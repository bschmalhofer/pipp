<?php

/*

=head1 NAME

t/in_php/array.t - tests for the PhpArray type

=head1 SYNOPSIS

    perl t/harness t/in_php/array.t

=head1 DESCRIPTION

Test array.

=head1 TODO

Set up tests in an array, like in arithmetics.t

=cut

*/

require_once 'Test.php';

plan(8);

$hello['world'] = 'hi';
$hello['World'] = 'Hi';
$hello['WORLD'] = 'HI';

is( $hello['world'], 'hi', "hello['world']");

is( $hello['World'], 'Hi', "hello['World']");

is( $hello['WORLD'], 'HI', "hello['WORLD']");

$thrice[3] = 9;
$thrice[2] = 6;

is( $thrice[3], 9, "thrice[3]");

is( $thrice[2], 6, "thrice[2]");

is( "3 times 3 equals $thrice[3]", "3 times 3 equals 9", "3 times 3 equals 9");

is( count($hello), 3, 'count of $hello');
is( count($thrice), 2, 'count of $thrice');

# vim: expandtab shiftwidth=4 ft=php:
?>
