=begin comments

Pipp::Grammar::Actions - AST transformations for Pipp

This file contains the methods that are used by the parse grammar
to build the PAST representation of a Pipp program.
Each method below corresponds to a rule in F<src/pct/grammar.pg>,
and is invoked at the point where C<{*}> appears in the rule,
with the current match object as the first argument.  If the
line containing C<{*}> also has a C<#= key> comment, then the
value of the comment is passed as the second argument to the method.

=end comments

=cut

class Pipp::Grammar::Actions;

method TOP($/, $key) {
    our $?NS    := '';
    our $?CLASS := '';
    our @?BLOCK; # A stack of PAST::Block
    our @?SUPER_GLOBALS :=
          ( '$_GET', '$_POST', '$_SERVER', '$_GLOBALS',
            '$_FILES', '$_COOKIE', '$_SESSION', '$_REQUEST', '$_ENV' );

    if $key eq 'open' {

        # Create the main startup block.
        my $main := PAST::Block.new(:hll('pipp'), :pirflags(':main') );

        # This makes sure that needed libs are loaded
        $main.loadinit().push(
            PAST::Op.new( :inline("    $P0 = compreg 'Pipp'",
                                  "    unless null $P0 goto pipp_pbc_is_loaded",
                                  "        load_bytecode 'pipp.pbc'",
                                  "  pipp_pbc_is_loaded:")
            )
        );

        # by default all symbols are lexical
        $main.symbol_defaults( :scope('lexical') );

        # set up scope 'package' for the superglobals
        for ( @?SUPER_GLOBALS ) { $main.symbol( :scope('package'), $_ ); }

        @?BLOCK.unshift($main);
    }
    else {
        # retrieve the block created in the "if" section in this method.
        my $block := @?BLOCK.shift();

        # a PHP script consists of a list of statements
        for $<sea_or_code> {
            $block.push( $_.ast );
        }

        make $block;
    }
}

method sea_or_code($/, $key) {
    make $/{$key}.ast;
}

# The sea, text, surrounding the island, code, is printed out
method SEA($/) {
    make PAST::Op.new(
        :name('echo'),
        :node($/),
        ~$/
    );
}

method code_short_tag($/) {
    make $<statement_list>.ast;
}

method code_echo_tag($/) {
    my $stmts := $<statement_list>.ast;

    my $echo := $<argument_list>.ast;
    $echo.name( 'echo' );

    $stmts.unshift( $echo );

    make $stmts;
}

method code_script_tag($/) {
    make $<statement_list>.ast;
}

method statement($/, $key) {
    make $/{$key}.ast;
}

method statement_list($/) {
    my $stmts := PAST::Stmts.new( :node($/) );
    for $<statement> {
        $stmts.push( $_.ast );
    }

    make $stmts;
}

method block($/) {
    make $<statement_list>.ast;
}

method inline_sea_short_tag($/) {
   make PAST::Op.new(
       :node($/),
       :name('echo'),
       ~$<SEA_empty_allowed>
   );
}

method namespace_definition($/, $key) {
    our $?NS;

    if $key eq 'open' {
        $?NS := +$<namespace_name> ?? ~$<namespace_name>[0] ~ '\\' !! '';
    }
    else {
        my $block :=
            PAST::Block.new(
                :namespace($?NS),
                :blocktype('immediate'),
                $<block>.ast
            );
        $?NS := '';

        make $block;
    }
}

method return_statement($/) {
    make PAST::Op.new(
        :name('return'),
        :pasttype('call'),
        :node( $/ ),
        $/<expression>.ast
    );
}

method require_once_statement($/) {
    make PAST::Op.new(
        :name('require'),
        :pasttype('call'),
        :node( $/ ),
        $/<quote>.ast
    );
}

method echo_statement($/) {
    my $past := $<argument_list>.ast;
    $past.name( 'echo' );

    make $past;
}

method print_statement($/) {
    make PAST::Op.new(
        :pasttype('call'),
        :name('print'),
        :node($/),
        $<expression>.ast
    );
}

method expression_statement($/) {
    make $<expression>.ast;
}

method closure_call($/) {
    my $past := $<argument_list>.ast;
    $past.unshift( $<var>.ast );

    make $past;
}

method function_call($/) {
    my $past := $<argument_list>.ast;
    $past.name( ~$<function_name> );

    make $past;
}

method instantiate_array($/) {
    my $past := PAST::Op.new(
                    :pasttype( 'call' ),
                    :name( 'array' ),
                    :node( $/ )
                );

    for $<array_argument> {
        $past.push( $_.ast );
    }

    make $past;
}

method array_argument($/, $key) {
    make $/{$key}.ast;
}

method key_value_pair($/) {
   make PAST::Op.new(
       :node( $/ ),
       :pasttype( 'call' ),
       :name( 'infix:=>' ),
       :returns( 'Array' ),
        $<key>.ast,
        $<value>.ast
   );
}

method method_call($/) {
    my $past := $<argument_list>.ast;
    $past.name( ~$<method_name> );
    $past.pasttype( 'callmethod' );
    $past.unshift( $<var>.ast );

    make $past;
}

# TODO: Call the default constructor without explicit check, inherit from PippObject instead
method constructor_call($/) {
    my $class_name := ~$<class_name>;
    # The constructor needs a list of it's arguments, or an empty list
    my $cons_call  := +$<argument_list> ??
                         $<argument_list>[0].ast
                        !!
                        PAST::Op.new();
    $cons_call.pasttype('callmethod');
    # The object onto which the method is called
    $cons_call.unshift(
        PAST::Op.new(
            :inline('%r = new %0', 'obj = %r'),
            $class_name
        )
    );
    # The method comes before the first argument
    $cons_call.unshift(
        PAST::Var.new(:name('cons'), :scope('register'))
    );

    make PAST::Stmts.new(
        PAST::Var.new( :name('obj'),  :scope('register'), :isdecl(1) ),
        PAST::Var.new( :name('cons'), :scope('register'), :isdecl(1) ),
        # use default constructor when there is no explicit constructor
        PAST::Op.new(
            :pasttype('if'),
            PAST::Op.new(
                :pirop('isnull'),
                PAST::Op.new( :inline("%r = get_global ['" ~ $class_name ~ "'], '__construct'") )  # condition
            ),
            PAST::Op.new( :inline("cons = get_global ['PippObject'], '__construct'") ),
            PAST::Op.new( :inline("cons = get_global ['" ~ $class_name ~ "'], '__construct'") )
        ),
        $cons_call,                                       # call the constructor
        PAST::Var.new( :name('obj'), :scope('register') ) # return the created object
    );
}

method constant($/) {
    our $?NS;
    our $?CLASS;
    my $ns   := $?CLASS eq '' ?? $?NS
                              !! $?NS ~ '\\' ~ $?CLASS ~ '::';
    if $<name><leading_backslash> {
        # fully qualified name
        make PAST::Var.new(
            :name(~$<name><ident>),
            :scope('package'),
            :namespace(~$<name><ns_path>)
        );
    }
    else {
        # access relative to current namespace
        make PAST::Var.new(
            :name(~$<name><ident>),
            :scope('package'),
            :namespace($ns ~ $<name><ns_path>)
        );
    }
}

method static_member($/) {
    our $?NS;
    our $?CLASS;
    make PAST::Var.new(
        :scope('package'),
        :namespace( $?NS ~'\\' ~ $?CLASS ~ '::'),
        :name(~$<ident>)
    );
}

# TODO: merge with rule 'constant'
method class_constant($/) {
    our $?NS;
    make PAST::Var.new(
        :scope('package'),
        :namespace( $?NS ~ '\\' ~ $<class_name> ~ '::'),
        :name(~$<name>)
    );
}

method constant_definition($/) {
    our $?CLASS;
    our $?NS;
    my $past := PAST::Block.new(:blocktype('immediate'));
    my $ns   := $?CLASS eq '' ?? $?NS
                              !! $?NS ~ '\\' ~ $?CLASS ~ '::';
    $past.loadinit().push(
        PAST::Op.new(
            :pasttype('bind'),
            PAST::Var.new(
                :name(~$<ident>),
                :isdecl(1),
                :scope('package'),
                :viviself('PhpNull'),
                :namespace($ns)
            ),
            $<literal>.ast
        )
    );

    make $past;
}

method global_declaration($/) {

    # variables are 'lexical' in the current block,
    # unless they are found in the symbol table of the current block
    our @?BLOCK;
    unless ( @?BLOCK[0].symbol( ~$<var_name> ) ) {
        @?BLOCK[0].symbol(
            ~$<var_name>, :comment('global_declaration')
        );
    }

    make PAST::Stmts.new(
        :name("global_definition of $<var_name>")
    );
}

method argument_list($/) {
    my $past := PAST::Op.new(
                    :pasttype('call'),
                    :node($/)
                );
    for $<expression> {
        $past.push( $_.ast );
    }

    make $past;
}


method do_while_statement($/) {
    make PAST::Op.new(
        :pasttype('repeat_while'),
        :node($/),
        $<expression>.ast,
        $<block>.ast
    );
}

method if_statement($/) {
    my $past := PAST::Op.new(
        :node($/),
        :pasttype('if'),
        $<expression>.ast,
        $<block>.ast
    );

    my $else := undef;
    if +$<else_clause> {
        $else := $<else_clause>[0]<block>.ast;
    }
    my $first_eif := undef;
    if +$<elseif_clause> {
        my $count := +$<elseif_clause> - 1;
        $first_eif := $<elseif_clause>[$count].ast;
        while $count != 0 {
            my $eif := $<elseif_clause>[$count].ast;
            $count--;
            my $eifchild := $<elseif_clause>[$count].ast;
            if ($else) {
                $eif.push($else);
            }
            $eif.push($eifchild);
        }
        if $else && +$<elseif_clause> == 1 {
            $first_eif.push($else);
        }
    }

    if $first_eif {
        $past.push($first_eif);
    }
    elsif $else {
        $past.push($else);
    }

    make $past;
}

method elseif_clause($/) {
    make PAST::Op.new(
        :node($/),
        :pasttype('if'),
        $<expression>.ast,
        $<block>.ast
    );
}

# taken from lolcode
method switch_statement($/) {
    my $past;
    my $it    := $<expression>.ast;
    my $count := +$<literal>;
    if $count >= 1 {
        # there is at least a single case
        $count    := $count - 1;
        my $val   := $<literal>[$count].ast;
        my $then  := PAST::Block.new(
                         :blocktype('immediate'),
                         $<statement_list>[$count].ast
                     );
        my $expr  := PAST::Op.new(
                         :pasttype('call'),
                         :name('infix:=='),
                         $it,
                         $val
                     );
        $past  := PAST::Op.new(
                      :pasttype('if'),
                      :node( $/ ),
                      $expr,
                      $then
                  );
    }
    else {
        # there are no cases, however there might be a 'default'
        $past := PAST::Stmts.new();
    }
    if ( $<default> ) {
        my $default := $<default>[0].ast;
        # $default.blocktype('immediate');
        $past.push( $default );
    }
    while ($count > 0) {
        $count := $count - 1;
        my $val   := $<literal>[$count].ast;
        my $expr  := PAST::Op.new(
                         :pasttype('call'),
                         :name('infix:=='),
                         $it,
                         $val
                     );
        my $then  := PAST::Block.new(
                         :blocktype('immediate'),
                         $<statement_list>[$count].ast
                     );
        $past  := PAST::Op.new(
                      :pasttype('if'),
                      :node( $/ ),
                      $expr,
                      $then,
                      $past
                  );
    }

    make $past;
}

method var_assign($/) {
    make PAST::Op.new(
        :pasttype('bind'),
        $<var>.ast,
        $<expression>.ast,
    );
}

method array_elem($/) {
    our @?BLOCK;
    unless @?BLOCK[0].symbol( ~$<var_name> ) {
        @?BLOCK[0].symbol( ~$<var_name>, :scope('lexical') );
        @?BLOCK[0].push(
            PAST::Var.new(
                :name(~$<var_name>),
                :viviself('PhpArray'),
                :isdecl(1)
            )
        );
    }

    make PAST::Var.new(
        :scope('keyed'),
        :viviself('PhpNull'),
        :lvalue(1),
        PAST::Var.new(
            :name(~$<var_name>),
            :viviself('PhpArray'),
            :lvalue(1),
        ),
        $<expression>.ast
    );
}

method simple_var($/) {

    # variables are 'lexical' in the current block,
    # unless they are found in the symbol table of the current block
    our @?BLOCK;
    unless @?BLOCK[0].symbol( ~$<var_name> ) {
        @?BLOCK[0].symbol(
            :scope('lexical'),
            ~$<var_name>
        );
        @?BLOCK[0].push(
            PAST::Var.new(
                :name(~$<var_name>),
                :viviself('PhpNull'),
                :isdecl(1)
            )
        );
    }

    make PAST::Var.new(
        :name(~$<var_name>),
        :viviself('PhpNull'),
        :lvalue(1),
    );
}

method var($/, $key) {
    make $/{$key}.ast;
}

method this($/) {
    make PAST::Op.new( :inline( "%r = self" ) );
}

method member($/) {
    make PAST::Op.new(
        :pasttype('callmethod'),
        :name('member'),
        PAST::Var.new(
            :name('$this'),
            :scope('lexical')
        )
    );
}

method while_statement($/) {
    make PAST::Op.new(
        :node($/),
        :pasttype('while'),
        $<expression>.ast,
        $<block>.ast
    );
}

method for_statement($/) {
    my $init  := $<var_assign>.ast;

    my $cond  := $<expression>[0].ast;
    my $work  := PAST::Stmts.new( $<block>.ast, $<expression>[1].ast );
    my $while := PAST::Op.new(
                       $cond,
                       $work,
                       :pasttype('while'),
                 );

    make PAST::Stmts.new( $init, $while );
}


# Handle the operator precedence table.
method expression($/, $key) {
    if $key eq 'end' {
        make $<expr>.ast;
    }
    else {
        my $past := PAST::Op.new( :name($<type>),
                                  :pasttype($<top><pasttype>),
                                  :pirop($<top><pirop>),
                                  :lvalue($<top><lvalue>),
                                  :node($/)
                                );
        for @($/) {
            $past.push( $_.ast );
        }

        make $past;
    }
}


method term($/, $key) {
    make $/{$key}.ast;
}

method literal($/, $key) {
    make $/{$key}.ast;
}

method true($/) {
    make PAST::Val.new(
        :value( 1 ),
        :returns('PhpBoolean'),
        :node($/)
    );
}

method false($/) {
    make PAST::Val.new(
        :value( 0 ),
        :returns('PhpBoolean'),
        :node($/)
    );
}

method null($/) {
    make PAST::Val.new(
        :value( 0 ),
        :returns('PhpNull'),
        :node($/)
    );
}

method integer($/) {
    make PAST::Val.new(
        :value( ~$/ ),
        :returns('PhpInteger'),
        :node($/)
    );
}

method number($/) {
    make PAST::Val.new(
        :value( +$/ ),
        :returns('PhpFloat'),
        :node($/)
    );
}

method closure($/, $key) {
    our @?BLOCK; # A stack of PAST::Block

    if $key eq 'open' {
        # note that $<param_list> creates a new PAST::Block.
        my $block := $<param_list>.ast;

        # set up scope 'package' for the superglobals
        our @?SUPER_GLOBALS;
        for ( @?SUPER_GLOBALS ) { $block.symbol( :scope('package'), $_ ); }

        # declare the bound vars a lexical
        if +$<bind_list> == 1 {
            for $<bind_list>[0]<var_name> {
                $block.symbol( ~$_, :comment('bound with use') );
            }
        }
        @?BLOCK.unshift( $block );
    }
    else {
        my $block := @?BLOCK.shift();

        $block.control('return_pir');
        $block.push( $<block>.ast );

        make $block;
    }
}

method function_definition($/, $key) {
    our @?BLOCK; # A stack of PAST::Block

    if $key eq 'open' {
        # note that $<param_list> creates a new PAST::Block.
        my $block := $<param_list>.ast;

        # set up scope 'package' for the superglobals
        our @?SUPER_GLOBALS;
        for ( @?SUPER_GLOBALS ) { $block.symbol( :scope('package'), $_ ); }

        @?BLOCK.unshift( $block );
    }
    else {
        my $block := @?BLOCK.shift();

        $block.name( ~$<function_name> );
        $block.control('return_pir');
        $block.push( $<block>.ast );

        make $block;
    }
}

method class_member_definition($/) {
    our @?BLOCK; # A stack of PAST::Block

    my $past := PAST::Stmts.new();
    my $member_name := ~$<var_name><ident>;

    # declare the attribute
    my $block := @?BLOCK[0];
    $block.symbol( $member_name, :scope('attribute') );

    # accessor method for the attribute
    $past.push(
        PAST::Block.new(
            :blocktype('method'),
            :name($member_name),
            PAST::Var.new( :name($member_name) )
        )
    );

    # create the attribute
    my $call_meta_attribute := 
        PAST::Op.new(
            :pasttype('call'),
            :name('pipp_meta_attribute'),
            PAST::Var.new(
                :name('metaclass'),
                :scope('register')
            ),
            $member_name
        );

    # Now the init closure
    if $<literal> {
        my $init_value :=
            PAST::Val.new(
                :value( ~$<literal>),
                :returns( 'PhpString' )
            );
        my $init_value := make_attr_init_closure($<literal>.ast);
        $init_value.named('init_value');
        $call_meta_attribute.push($init_value);
    }
    $past.push( $call_meta_attribute );

    make $past;
}

method class_static_member_definition($/) {
    our $?CLASS;
    our $?NS;
    my $past := PAST::Block.new(:blocktype('immediate'));
    my $ns   := $?CLASS eq '' ?? $?NS
                              !! $?NS ~ '\\' ~ $?CLASS ~ '::';
    my $member_name := ~$<var_name><ident>;
    $past.loadinit().push(
        PAST::Op.new(
            :pasttype('bind'),
            PAST::Var.new(
                :name($member_name),
                :isdecl(1),
                :scope('package'),
                :viviself('PhpNull'),
                :namespace($ns)
            ),
            $<literal>.ast
        )
    );

    make $past;
}

method class_method_definition($/, $key) {
    our @?BLOCK; # A stack of PAST::Block

    if $key eq 'open' {
        # note that $<param_list> creates a new PAST::Block.
        my $block := $<param_list>.ast;
        $block.name( ~$<method_name> );
        $block.blocktype( 'method' );
        $block.control('return_pir');

        $block.push(
            PAST::Op.new(
                :pasttype('bind'),
                PAST::Var.new(
                    :name('$this'),
                    :scope('lexical'),
                    :isdecl(1)
                ),
                PAST::Var.new(
                    :name('self'),
                    :scope('register')
                )
            )
        );

        # set up scope 'package' for the superglobals
        our @?SUPER_GLOBALS;
        for ( @?SUPER_GLOBALS ) { $block.symbol( :scope('package'), $_ ); }

        @?BLOCK.unshift( $block );
    }
    else {
        our $?NS;
        our $?CLASS;
        my $ns := $?NS ~ '\\' ~ $?CLASS ~ '::';

        my $block := @?BLOCK.shift();

        $block.push(
            PAST::Op.new(
                :pasttype('bind'),
                PAST::Var.new(
                    :name('__METHOD__'),
                    :isdecl(1),
                    :scope('package'),
                    :viviself('PhpNull'),
                    :namespace($ns)
                ),
                PAST::Val.new(
                    :value($block.name()),
                    :returns('PhpString'),
                )
            )
        );

        $block.push( $<block>.ast );

        make $block;
    }
}

method param_list($/) {
    my $block := PAST::Block.new( :blocktype('declaration'), :node($/) );
    my $arity := 0;
    for $<var_name> {
        $block.push(
            PAST::Var.new(
                :name(~$_),
                :scope('parameter'),
            )
        );

        $arity++;
        $block.symbol( ~$_, :scope('lexical') );
    }
    $block.arity( $arity );

    make $block;
}

method break($/) {
    make PAST::Stmts.new( :name('break') );
}

method empty_statement($/) {
    make PAST::Stmts.new( :name('empty statement') );
}

method class_definition($/, $key) {
    our @?BLOCK; # A stack of PAST::Block
    our $?CLASS; # for namespacing of constants
    if $key eq 'open' {
        $?CLASS := ~$<class_name>;
        our $?NS;

        my $block := PAST::Block.new(
            :node($/),
            :blocktype('declaration'),
            :pirflags( ':init :load' ),
            :namespace( Pipp::Compiler.parse_name($?CLASS) )
        );

        # Start of class definition; make PAST to create class object
        $block.push(
            PAST::Op.new(
                :pasttype('bind'),
                PAST::Var.new(
                    :name('metaclass'),
                    :scope('register'),
                    :isdecl(1)
                ),
                PAST::Op.new(
                    :pasttype('call'),
                    :name('pipp_meta_create'),
                    'class',
                    $?CLASS
                )
            )
        );

        # assign predeclared constant __CLASS__
        my $ns := $?NS ~ '\\' ~ $?CLASS ~ '::';
        $block.push(
            PAST::Op.new(
                :pasttype('bind'),
                PAST::Var.new(
                    :name('__CLASS__'),
                    :isdecl(1),
                    :scope('package'),
                    :viviself('PhpNull'),
                    :namespace($ns)
                ),
                PAST::Val.new(
                    :value($?CLASS),
                    :returns('PhpString'),
                )
            )
        );

        # set up scope 'package' for the superglobals
        our @?SUPER_GLOBALS;
        for ( @?SUPER_GLOBALS ) { $block.symbol( :scope('package'), $_ ); }

        @?BLOCK.unshift( $block );
    }
    else {
        my $block := @?BLOCK.shift();

        # setup of class constants is done in the 'loadinit' node
        for $<class_member_or_method_definition> {
            $block.push( $_.ast );
        }

        # It's a new class definition. Make proto-object.
        $block.push(
            PAST::Op.new(
                :pasttype('call'),
                :name('pipp_meta_compose'),
                PAST::Var.new(
                    :scope('register'),
                    :name('metaclass')
                )
            )
        );

        $?CLASS := '';

        make $block;
    }
}

method class_member_or_method_definition($/, $key) {
    make $/{$key}.ast;
}

method quote($/) {
    make $<quote_expression>.ast;
}

method quote_expression($/, $key) {
    my $past;
    if $key eq 'quote_regex' {
        $past := PAST::Block.new(
            $<quote_regex>,
            :compiler('PGE::Perl6Regex'),
            :blocktype('declaration'),
            :node( $/ )
        );
    }
    elsif $key eq 'quote_concat' {
        if +$<quote_concat> == 1 {
            $past := $<quote_concat>[0].ast;
        }
        else {
            $past := PAST::Op.new(
                :name('list'),
                :pasttype('call'),
                :node( $/ )
            );
            for $<quote_concat> {
                $past.push( $_.ast );
            }
        }
    }
    make $past;
}

method quote_concat($/) {
    my $terms := +$<quote_term>;
    my $count := 1;
    my $past := $<quote_term>[0].ast;
    while ($count != $terms) {
        $past := PAST::Op.new(
            $past,
             $<quote_term>[$count].ast,
            :pirop('concat'),
            :pasttype('pirop')
        );
        $count := $count + 1;
    }
    make $past;
}

method quote_term($/, $key) {
    my $past;
    if $key eq 'literal' {
        $past := PAST::Val.new(
            :value( ~$<quote_literal>.ast ),
            :returns('PhpString'),
            :node($/)
        );
    }
    else {
        $past := $/{$key}.ast;
    }
    make $past;
}

method curly_interpolation($/) {
    make $<var>.ast;
}

sub make_attr_init_closure($init_value) {
    # Need to not just build the closure, but new_closure it; otherwise, we
    # run into trouble if our initialization value involves a parameter from
    # a parametric role.
    PAST::Op.new(
        :inline('%r = newclosure %0'),
        PAST::Block.new(
            :blocktype('method'),
            PAST::Stmts.new(
                PAST::Var.new( :name('$_'), :scope('parameter') ),
                PAST::Op.new( :pasttype('bind'),
                    PAST::Var.new( :name('self'), :scope('lexical'), :isdecl(1) ),
                    PAST::Var.new( :name('self'), :scope('register') )
                )
            ),
            PAST::Stmts.new( $init_value )
        )
    );
}


# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
