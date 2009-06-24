<?php

# Copyright (C) 2008, The Perl Foundation.

/*

=head1 NAME

t/in_php/ops.t - test various ops

=head1 SYNOPSIS

    perl t/harness t/in_php/ops.t

=head1 DESCRIPTION

Test various operators.

=cut

*/

require_once 'Test.php';

plan(2);

$x = ( $y = 2 ) * 3;
is( $x, 6, 'multiplication');
is( $y, 2, 'inner assignment');

# vim: expandtab shiftwidth=4 ft=php:
?>
