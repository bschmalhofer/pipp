class Pipp::Compiler is HLL::Compiler;

INIT {
    Pipp::Compiler.language('Pipp');
    Pipp::Compiler.parsegrammar(Pipp::Grammar);
    Pipp::Compiler.parseactions(Pipp::Actions);
}
