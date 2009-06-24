
=head1 NAME

src/common/guts.pir - subs that are part of the internals, not for users

=head1 HISTORY

Stolen from Rakudo.

=head1 SUBS

=over 4

=item C<bool pipp_defined(string constant_name)>

Check whether a Parrot register is defined.

=cut

.sub 'pipp_defined'
    .param pmc args :slurpy
    .local int argc

    argc = args
    unless argc != 1 goto L1
    wrong_param_count()
    .RETURN_NULL()
  L1:
    $P0 = shift args
    $I0 = defined $P0
    .return ($I0)
.end

=item C<void pipp_var_dump(mixed var)>

Dump a PMC

=cut

.sub 'pipp_var_dump'
    .param pmc args :slurpy
    .local int argc

    argc = args
    unless argc != 1 goto L1
    wrong_param_count()
    .return()
  L1:
    $P0 = shift args
    _dumper($P0)

    .return ()
.end


.include 'except_types.pasm'
.include 'except_severity.pasm'

=item return

For returning a value from a function.

=cut

.sub 'return'
    .param pmc value           :optional
    .param int has_value       :opt_flag

    if has_value goto have_value
    value = 'list'()
  have_value:
    $P0         = new 'Exception'
    $P0['type'] = .CONTROL_RETURN
    setattribute $P0, 'payload', value
    throw $P0
    .return (value)
.end

=item pipp_meta_create(type,name)

Internal helper method to create a class.
See C<!keyword_class> in Rakudo.

=cut

.sub 'pipp_meta_create'
    .param string type
    .param string name

    .local pmc nsarray
    $P0 = get_hll_global [ 'Pipp';'Compiler' ], 'parse_name'
    $P1 = null
    nsarray = $P0($P1, name)

    if type == 'class' goto class
    'die'("Unsupported type ", type)

  class:
    .local pmc ns, metaclass
    ns = get_hll_namespace nsarray
    metaclass = newclass ns

    .return (metaclass)
.end

=item pipp_meta_compose()

Default meta composer -- does nothing.

=cut

.sub 'pipp_meta_compose' :multi()
    .param pmc metaclass
    # Currently, nothing to do.
    .return (metaclass)
.end

=item pipp_meta_compose(Class metaclass)

Compose the class. This includes resolving any inconsistencies
and creating the protoobjects.

=cut

.sub 'pipp_meta_compose' :multi(['Class'])
    .param pmc metaclass

    .local pmc p6meta
    p6meta = get_hll_global ['PippObject'], '$!P6META'

    .tailcall p6meta.'register'(metaclass, 'parent' => 'PippObject')
.end


=item pipp_meta_trait(metaclass, type, name)

Add a trait with the given C<type> and C<name> to C<metaclass>.

=cut

.sub 'pipp_meta_trait'
    .param pmc metaclass
    .param string type
    .param string name

    if type == 'trait_auxiliary:extends' goto extends
    'die'("Unknown trait auxiliary ", type)

  extends:
    .local pmc nsarray
    $P0 = get_hll_global [ 'Pipp';'Compiler' ], 'parse_name'
    $P1 = null
    nsarray = $P0($P1, name)
    $S0 = pop nsarray
    $P0 = get_hll_global nsarray, $S0

    ##  add it as parent to metaclass
    $P1 = get_hll_global ['PippObject'], '$!P6META'
    $P0 = $P1.'get_parrotclass'($P0)
    metaclass.'add_parent'($P0)

    .return ()
.end


=item pipp_meta_attribute(class, name)

Adds an attribute with the given name to the class.
See C<!keyword_has> in Rakudo.

=cut

.sub 'pipp_meta_attribute'
    .param pmc    metaclass
    .param string name
    .param pmc    attr          :slurpy :named

    # TODO: check whether the attr exists
    # $P77 = get_root_global ['parrot'], '_dumper'
    # $P77(metaclass, 'metaclass')
    # $P77(name, 'name')
    addattribute metaclass, name

    .local pmc attrhash
    $P0 = metaclass.'attributes'()
    attrhash = $P0[name]
    # $P77(attrhash, 'attrhash')

    # and set any other attributes that came in via the slurpy hash
    .local pmc it
    it = iter attr
  attr_loop:
    unless it goto attr_done
    $S0 = shift it
    $P0 = attr[$S0]
    attrhash[$S0] = $P0
    goto attr_loop
  attr_done:

    .return ()
.end

=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
