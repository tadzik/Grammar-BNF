my class Actions { ... }

grammar Grammar::BNF {
    token TOP {
        \s* <rule>+ \s*
    }

    # Apparently when used for slang we need a lowercase top rule?
    token main_syntax {
        <TOP>
    }

    token rule {
        <opt-ws> '<' <rule-name> '>' <opt-ws> '::=' <opt-ws> <expression> <line-end>
    }

    token opt-ws {
        \h*
    }

    token rule-name {
        <-[>]>+
    }

    token expression {
        <list> +% [\s* '|' <opt-ws>]
    }

    token line-end {
        [ <opt-ws> \n ]+
    }

    token list {
        <term> +% <opt-ws>
    }

    token term {
        <literal> | '<' <rule-name> '>'
    }

    token literal {
        '"' <-["]>* '"' | "'" <-[']>* "'"
    }

    # Provide a parse with defaults and also define our per-parse scope.
    method parse(|c) {
        my $*name = c<name> // 'BNFGrammar';
        nextsame if (c<actions>);
        nextwith(|c, :actions(Actions));
    }

    # We may want to rename this given jnthn's Grammar::Generative
    method generate(|c) {
        my $res = self.parse(|c);
        fail("parse *of* an BNF grammar definition failed.") unless $res;
	return $res.ast;
    }
}

my class Actions {

    my sub guts($/, $rule) {
	# Note: $*name can come from .parse above or from Slang::BNF
        my $grmr := Metamodel::GrammarHOW.new_type(:name($*name));
        $grmr.^add_method('TOP', EVAL 'token { <' ~ $rule[0].ast.key ~ '> }');
        for $rule.map(*.ast) -> $rule {
            $grmr.^add_method($rule.key, $rule.value);
        }
        $grmr.^compose;
    }

    method TOP($/) {
        make guts($/, $<rule>);
    }

    method main_syntax($/) {
        make guts($/, $<TOP><rule>);
    }

    method rule($/) {
        make $<rule-name>.ast => $<expression>.ast;
    }

    method rule-name($/) {
        make ~$/;
    }

    method expression($/) {
        make EVAL 'token { [ ' ~ $<list>.map(*.ast).join(' | ') ~ ' ] }';
    }

    method list($/) {
        make $<term>.map(*.ast).join(' ');
    }

    method term($/) {
        make ~$/;
    }

    method literal($/) {
        make ~$/;
    }
}

# For the slang guts we need an actions class we can find.
class Grammar::BNF-actions is Actions { };
