=begin overview

This is the grammar for Pipp in Perl 6 rules.

=end overview

grammar Pipp::Grammar is HLL::Grammar;

token begin_TOP {
    <?>
}

token TOP {
    <.begin_TOP>
    <sea_or_island_list>
    [ $ || <.panic: "Syntax error"> ]
}

## Lexer items

# This <ws> rule does not handle comments
token ws {
    <!ww>
    [ \s+ ]*
}

## code islands in a sea of text

rule sea_or_island_list { <sea_or_island>* }

rule sea_or_island {
    | <island_script_tag>
    | <island_short_tag>
    | <sea>
}

rule sea {
    '<'? .+? ( <before '<'> | $ )
}

## long script tags

rule island_script_tag {
    <.open_script_tag>
        <statementlist>
    <.close_script_tag>?
}

token quoted_lang_name { '"php"' | '\'php\'' }

rule open_script_tag {
    '<script' <.ws> 'language' <.ws>? '=' <.ws>? <quoted_lang_name> <.ws>? '>'
}

rule close_script_tag {
    '</script' <.ws>? '>'
}

## short tags

token open_short_tag {
    '<?' 'php'?
}

token close_short_tag {
    '?>' \n?
}

rule island_short_tag {
    <.open_short_tag>
        <statementlist>
    <.close_short_tag>?
}

## Statements

rule statementlist {
    <stat_or_def>*
}

rule stat_or_def {
    | <statement>
    | <sub_definition>
}

rule sub_definition {
    'function' <identifier> <parameters> '{'
    <statement>*
    '}'
}

rule parameters {
   '(' [<identifier> ** ',']? ')'
}

proto rule statement { <...> }

rule statement:sym<assignment> {
    <primary> '=' <EXPR>
}

rule statement:sym<do> {
    <sym> <block> 'end'
}

rule statement:sym<for> {
    <sym> <for_init> ',' <EXPR> <step>?
    'do' <statement>* 'end'
}

rule step {
    ',' <EXPR>
}

rule for_init {
    'var' <identifier> '=' <EXPR>
}

rule statement:sym<if> {
    <sym> <EXPR> 'then' $<then>=<block>
    ['else' $<else>=<block> ]?
    'end'
}

rule statement:sym<sub_call> {
    <primary> <arguments> ';'
}

rule arguments {
    '(' [<EXPR> ** ',']? ')'
}

rule statement:sym<throw> {
    <sym> <EXPR>
}

rule statement:sym<try> {
    <sym> $<try>=<block>
    'catch' <exception>
    $<catch>=<block>
    'end'
}

rule exception {
    <identifier>
}

rule statement:sym<var> {
    <sym> <identifier> ['=' <EXPR>]?
}

rule statement:sym<while> {
    <sym> <EXPR> 'do' <block> 'end'
}

token begin_block {
    <?>
}

rule block {
    <.begin_block>
    <statement>*
}

## Terms

rule primary {
    <identifier> <postfix_expression>*
}

proto rule postfix_expression { <...> }

rule postfix_expression:sym<index> { '[' <EXPR> ']' }

rule postfix_expression:sym<key> { '{' <EXPR> '}' }

rule postfix_expression:sym<member> { '.' <identifier> }

token identifier {
    <!keyword> <ident>
}

token keyword {
    ['and'|'catch'|'do'   |'else' |'end' |'for' |'if'
    |'not'|'or'   |'function'  |'throw'|'try' |'var'|'while']>>
}

token term:sym<integer_constant> { <integer> }
token term:sym<string_constant> { <string_constant> }
token string_constant { <quote> }
token term:sym<float_constant_long> { # longer to work-around lack of LTM
    [
    | \d+ '.' \d*
    | \d* '.' \d+
    ]
}
token term:sym<primary> {
    <primary>
}

proto token quote { <...> }
token quote:sym<'> { <?[']> <quote_EXPR: ':q'> }
token quote:sym<"> { <?["]> <quote_EXPR: ':qq'> }

## Operators

INIT {
    Pipp::Grammar.O(':prec<w>, :assoc<unary>', '%unary-negate');
    Pipp::Grammar.O(':prec<v>, :assoc<unary>', '%unary-not');
    Pipp::Grammar.O(':prec<u>, :assoc<left>',  '%multiplicative');
    Pipp::Grammar.O(':prec<t>, :assoc<left>',  '%additive');
    Pipp::Grammar.O(':prec<s>, :assoc<left>',  '%relational');
    Pipp::Grammar.O(':prec<r>, :assoc<left>',  '%conjunction');
    Pipp::Grammar.O(':prec<q>, :assoc<left>',  '%disjunction');
}

token circumfix:sym<( )> { '(' <.ws> <EXPR> ')' }

rule circumfix:sym<[ ]> {
    '[' [<EXPR> ** ',']? ']'
}

rule circumfix:sym<{ }> {
    '{' [<named_field> ** ',']? '}'
}

rule named_field {
    <string_constant> '=>' <EXPR>
}

token prefix:sym<-> { <sym> <O('%unary-negate, :pirop<neg>')> }
token prefix:sym<not> { <sym> <O('%unary-not, :pirop<isfalse>')> }

token infix:sym<*>  { <sym> <O('%multiplicative, :pirop<mul>')> }
token infix:sym<%>  { <sym> <O('%multiplicative, :pirop<mod>')> }
token infix:sym</>  { <sym> <O('%multiplicative, :pirop<div>')> }

token infix:sym<+>  { <sym> <O('%additive, :pirop<add>')> }
token infix:sym<->  { <sym> <O('%additive, :pirop<sub>')> }
token infix:sym<..> { <sym> <O('%additive, :pirop<concat>')> }

token infix:sym«<» { <sym> <O('%relational, :pirop<islt iPP>')> }
token infix:sym«<=» { <sym> <O('%relational, :pirop<isle iPP>')> }
token infix:sym«>» { <sym> <O('%relational, :pirop<isgt iPP>')> }
token infix:sym«>=» { <sym> <O('%relational, :pirop<isge iPP>')> }
token infix:sym«==» { <sym> <O('%relational, :pirop<iseq iPP>')> }
token infix:sym«!=» { <sym> <O('%relational, :pirop<isne iPP>')> }

token infix:sym<and> { <sym> <O('%conjunction, :pasttype<if>')> }
token infix:sym<or> { <sym> <O('%disjunction, :pasttype<unless>')> }
