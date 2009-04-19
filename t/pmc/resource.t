# Copyright (C) 2008, The Perl Foundation.

=head1 NAME

t/pmc/resource.t - Resource PMC

=head1 SYNOPSIS

    % perl t/harness t/pmc/resource.t

=head1 DESCRIPTION

Tests C<PhpBoolean> PMC.

=cut

.sub 'main' :main
    $P0 = loadlib "pipp_group"

    .include "test_more.pir"

    plan(2)

    type_tests()
.end

.sub type_tests
    .local pmc my_string, ref_to_my_string
    .local string type

    my_string = new 'PhpString'
    my_string = 'this is a Pipp String'
    ref_to_my_string = new 'PhpResource', my_string

    type = typeof my_string
    is(type, "string", "type of my_string")

    type = typeof ref_to_my_string
    is(type, "resource", "type of ref_to_my_string")

.end

# Local Variables:
#   mode: pir
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
