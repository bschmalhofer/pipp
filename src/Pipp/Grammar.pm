=begin overview

This is the grammar for Pipp in Perl 6 rules.

=end overview

grammar Pipp::Grammar is HLL::Grammar;

token TOP {
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

rule sea_or_island_list { [ <sea_or_island> | <?> ] ** ';' }

rule sea_or_island {
    | <island_script_tag>
    | <sea>
}

rule sea {
    '<'? .+? ( <before '<'> | $ )
}

## long tags

rule island_script_tag {
    <.open_script_tag>
        <statement_list>
    <.close_script_tag>?
}

token quoted_lang_name { '"php"' | '\'php\'' }

rule open_script_tag {
    '<script' <.ws> 'language' <.ws>? '=' <.ws>? <quoted_lang_name> <.ws>? '>'
}

rule close_script_tag {
    '</script' <.ws>? '>'
}


## Statements

rule statement_list { [ <statement> | <?> ] ** ';' }

rule statement {
    | <statement_control>
    | <EXPR>
}

proto token statement_control { <...> }
rule statement_control:sym<say>   { <sym> [ <EXPR> ] ** ','  }
rule statement_control:sym<print> { <sym> [ <EXPR> ] ** ','  }

## Terms

token term:sym<integer> { <integer> }
token term:sym<quote> { <quote> }

proto token quote { <...> }
token quote:sym<'> { <?[']> <quote_EXPR: ':q'> }
token quote:sym<"> { <?["]> <quote_EXPR: ':qq'> }

## Operators

INIT {
    Pipp::Grammar.O(':prec<u>, :assoc<left>',  '%multiplicative');
    Pipp::Grammar.O(':prec<t>, :assoc<left>',  '%additive');
}

token circumfix:sym<( )> { '(' <.ws> <EXPR> ')' }

token infix:sym<*>  { <sym> <O('%multiplicative, :pirop<mul>')> }
token infix:sym</>  { <sym> <O('%multiplicative, :pirop<div>')> }

token infix:sym<+>  { <sym> <O('%additive, :pirop<add>')> }
token infix:sym<->  { <sym> <O('%additive, :pirop<sub>')> }
