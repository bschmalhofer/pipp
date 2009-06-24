<?php

/*

=head1 NAME

t/php/base64.t - Standard Library base64

=head1 SYNOPSIS

    perl t/harness t/php/base64.t

=head1 DESCRIPTION

Tests PHP Standard Library base64
(implemented in F<languages/pipp/src/common/php_base64.pir>).

See L<http://www.php.net/manual/en/ref.url.php>.

=cut

*/

require_once 'Test.php';

plan(5);

is( base64_encode('Plum Headed Parakeet'), "UGx1bSBIZWFkZWQgUGFyYWtlZXQ=", 'base64_encode');

is( base64_encode(3.14), "My4xNA==", 'base64_encode(3.14)');

is( base64_encode(TRUE), "MQ==", 'base64_encode(TRUE)');

is( base64_encode(NULL), "", 'base64_encode(NULL)');

is( base64_decode('UGx1bSBIZWFkZWQgUGFyYWtlZXQ='), "Plum Headed Parakeet", 'base64_decode(str)');

/*

The following test are not executed, as STDERR is not captured yet.

like( base64_encode(), "base64_encode\(\) expects exactly 1 parameter, 0 given", 'base64_encode(no arg)');

language_output_like( 'Pipp', <<'CODE', <<'OUT', 'base64_encode(array)' );
<?php
  $hello['world'] = 'hi';
  echo base64_encode($hello), "\n";
?>
CODE
/base64_encode\(\) expects parameter 1 to be string, array given/
OUT

language_output_like( 'Pipp', <<'CODE', <<'OUT', 'base64_decode(no arg)' );
<?php
  echo base64_decode(), "\n";
?>
CODE
/base64_decode\(\) expects at least 1 parameter, 0 given/
OUT

*/

# vim: expandtab shiftwidth=4 ft=php:
?>
