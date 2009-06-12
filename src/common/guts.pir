
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

=item pipp_get_flattened_roles_list

Flattens out the list of roles.

=cut

.sub 'pipp_get_flattened_roles_list'
    .param pmc unflat_list
    .local pmc flat_list, it, cur_role, nested_roles, nested_it
    flat_list = root_new ['parrot';'ResizablePMCArray']
    it = iter unflat_list
  it_loop:
    unless it goto it_loop_end
    cur_role = shift it
    $I0 = isa cur_role, 'Role'
    unless $I0 goto error_not_a_role
    push flat_list, cur_role
    nested_roles = getprop '@!roles', cur_role
    if null nested_roles goto it_loop
    nested_roles = 'pipp_get_flattened_roles_list'(nested_roles)
    nested_it = iter nested_roles
  nested_it_loop:
    unless nested_it goto it_loop
    $P0 = shift nested_it
    push flat_list, $P0
    goto nested_it_loop
  it_loop_end:
    .return (flat_list)
  error_not_a_role:
    'die'('Can not compose a non-role.')
.end

=item pipp_compose_role_attributes(class, role)

Helper method to compose the attributes of a role into a class.

=cut

.sub 'pipp_compose_role_attributes'
    .param pmc class
    .param pmc role

    .local pmc role_attrs, class_attrs, ra_iter, fixup_list
    .local string cur_attr
    role_attrs = inspect role, "attributes"
    class_attrs = class."attributes"()
    fixup_list = root_new ['parrot';'ResizableStringArray']
    ra_iter = iter role_attrs
  ra_iter_loop:
    unless ra_iter goto ra_iter_loop_end
    cur_attr = shift ra_iter

    # Check that this attribute doesn't conflict with one already in the class.
    $I0 = exists class_attrs[cur_attr]
    unless $I0 goto no_conflict

    # We have a name conflict. Let's compare the types. If they match, then we
    # can merge the attributes.
    .local pmc class_attr_type, role_attr_type
    $P0 = class_attrs[cur_attr]
    if null $P0 goto conflict
    class_attr_type = $P0['type']
    if null class_attr_type goto conflict
    $P0 = role_attrs[cur_attr]
    if null $P0 goto conflict
    role_attr_type = $P0['type']
    if null role_attr_type goto conflict
    goto merge

  conflict:
    $S0 = "Conflict of attribute '"
    $S0 = concat cur_attr
    $S0 = concat "' in composition of role '"
    $S1 = role
    $S0 = concat $S1
    $S0 = concat "'"
    'die'($S0)

  no_conflict:
    addattribute class, cur_attr
    push fixup_list, cur_attr
  merge:
    goto ra_iter_loop
  ra_iter_loop_end:

    # Now we need, for any merged in attributes, to copy property data.
    .local pmc fixup_iter, class_props, role_props, props_iter
    class_attrs = class."attributes"()
    fixup_iter = iter fixup_list
  fixup_iter_loop:
    unless fixup_iter goto fixup_iter_loop_end
    cur_attr = shift fixup_iter
    role_props = role_attrs[cur_attr]
    class_props = class_attrs[cur_attr]
    props_iter = iter role_props
  props_iter_loop:
    unless props_iter goto props_iter_loop_end
    $S0 = shift props_iter
    $P0 = role_props[$S0]
    class_props[$S0] = $P0
    goto props_iter_loop
  props_iter_loop_end:
    goto fixup_iter_loop
  fixup_iter_loop_end:
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

Compose the class.  This includes resolving any inconsistencies
and creating the protoobjects.

=cut

.sub 'pipp_meta_compose' :multi(['Class'])
    .param pmc metaclass

    .local pmc p6meta
    p6meta = get_hll_global ['PippObject'], '$!P6META'

    # Parrot handles composing methods into roles, but we need to handle the
    # attribute composition ourselves.
    .local pmc roles, roles_it
    roles = getprop '@!roles', metaclass
    if null roles goto roles_it_loop_end
    roles = 'pipp_get_flattened_roles_list'(roles)
    roles_it = iter roles
  roles_it_loop:
    unless roles_it goto roles_it_loop_end
    $P0 = shift roles_it
    $I0 = does metaclass, $P0
    if $I0 goto roles_it_loop
    metaclass.'add_role'($P0)
    'pipp_compose_role_attributes'(metaclass, $P0)
    goto roles_it_loop
  roles_it_loop_end:

    .local pmc proto
    proto = p6meta.'register'(metaclass, 'parent' => 'PippObject')

    # See if there's any attribute initializers.
    .local pmc WHENCE
    $P0 = p6meta.'get_parrotclass'(proto)
    WHENCE = getprop '%!WHENCE', $P0
    if null WHENCE goto no_whence

    setprop proto, '%!WHENCE', WHENCE
  no_whence:
    .return (proto)
.end


=item pipp_meta_attribute(class, name)

Adds an attribute with the given name to the class.
See C<!keyword_has> in Rakudo.

=cut

.sub 'pipp_meta_attribute'
    .param pmc metaclass
    .param string name
    .param string itypename     :optional
    .param int    has_itypename :opt_flag
    .param pmc    attr          :slurpy :named

    # TODO: check whether the attr exists
    addattribute metaclass, name

    .local pmc attrhash, it
    $P0 = metaclass.'attributes'()
    attrhash = $P0[name]

    # Set any itype for the attribute.
    unless has_itypename goto itype_done
    .local pmc itype
    if itypename == 'PhpString' goto itype_pmc
    itype = get_class itypename
    goto have_itype
  itype_pmc:
    $P0 = get_root_namespace ['parrot';'PhpString']
    itype = get_class $P0
  have_itype:
    attrhash['itype'] = itype
  itype_done:

    .return ()
.end

=item !ADD_TO_WHENCE

Adds a key/value mapping to what will become the WHENCE on a proto-object (we
don't have a proto-object to stick them on yet, so we put a property on the
class temporarily, then attach it as the WHENCE clause later).

=cut

.sub '!ADD_TO_WHENCE'
    .param pmc class
    .param pmc attr_name
    .param pmc value

    # Get hash if we have it, if not make it.
    .local pmc whence_hash
    whence_hash = getprop '%!WHENCE', class
    unless null whence_hash goto have_hash
    whence_hash = new 'PhpArray'
    setprop class, '%!WHENCE', whence_hash

    # Make entry.
  have_hash:
    whence_hash[attr_name] = value
.end


=back

=cut

# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
