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

    plan(4)

    .local pmc my_string, ref_to_my_string, dereferenced
    .local string type

    # create a string 
    my_string = new 'PhpString'
    my_string = 'this is a Pipp String'
    type = typeof my_string
    is(type, "string", "type of my_string")

    # create a reference to the string
    ref_to_my_string = new 'PhpResource', my_string
    type = typeof ref_to_my_string
    is(type, "resource", "type of ref_to_my_string")

    # dereference the string
    dereferenced = deref ref_to_my_string
    type = typeof dereferenced
    is(type, "string", "type of dereferenced")
    diag(dereferenced)
    is(dereferenced, 'this is a Pipp String', 'content on dereferenced string')
    
.end

# Local Variables:
#   mode: pir
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
