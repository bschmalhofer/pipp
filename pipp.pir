# $Id$

=head1 TITLE

pipp.pir - A Pipp compiler.

=head2 Description

This is the entry point for the Pipp compiler.

=head2 Functions

=over 4

=item main(args :slurpy)  :main

Start compilation by passing any command line C<args>
to the Pipp compiler.

=cut

.sub 'main' :main
    .param pmc args

    load_language 'pipp'

    $P0 = compreg 'Pipp'
    $P1 = $P0.'command_line'(args)
.end

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:

