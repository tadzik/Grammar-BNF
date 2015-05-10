Grammar::BNF
========

Grammar::BNF Create Perl6 Grammars from BNF-like syntax

## Purpose

This distribution contains modules for creating Perl6 Grammar
objects using BNF flavored grammar definition syntax.  Currently
BNF and ABNF are supplied.

In addition, the distribution contains Slang modules which allow
use of the grammar definition syntax inline in Perl 6 code.  These
modules may relax their respective syntax slightly to allow for
smoother language integration.

## Idioms

This simple example shows how to turn a simple two-line grammar
definition in BNF syntax into a grammar named C<MyGrammar>, and
then uses the resulting grammar to parse the string 'barbar';

    use Grammar::BNF;
    my $g = Grammar::BNF.generate(Q:to<END>
                                  <foo2> ::= <foo> <foo>
                                  <foo> ::= "bar"
                                  END
                                  );
    $g.parse('barbar').say; # ｢barbar｣
                            #  foo2 => ｢barbar｣
                            #   foo => ｢bar｣
                            #   foo => ｢bar｣


Alternatively, you may use a slang to define grammars inline:

    use Slang::BNF;
    bnf-grammar MyGrammar {
        <foo2> ::= <foo> <foo>
        <foo> ::= "bar"
    }; # currently you need this semicolon
    MyGrammar.parse('barbar').say; # same as above

In either case, the first rule appearing in the grammar definition will
be aliased to 'TOP', and will be the default rule applied by C<.parse>.
This is in most respects a true Perl6 Grammar, so subrules may be invoked:

    MyGrammar.parse('bar',:rule<foo>).say; # ｢bar｣

...and the Grammar may be subclassed to add or replace rules with Perl 6
rules:

    grammar MyOtherGrammar is MyGrammar {
        token foo { B <ar> }
        token ar  { ar }
    }
    MyOtherGrammar.parse('BarBar').say; # ｢BarBar｣
                                        #  foo2 => ｢BarBar｣
                                        #   foo => ｢Bar｣
                                        #    ar => ｢ar｣
                                        #   foo => ｢Bar｣
                                        #    ar => ｢ar｣

Currently you have to subclass with a Perl 6 grammar for actions classes
to be provided, but hopefully that limitation will be overcome:

    class MyActions { method foo ($match) { "OHAI".say } }
    MyOtherGrammar.parse('BarBar', :actions(MyActions)); # says OHAI twice

