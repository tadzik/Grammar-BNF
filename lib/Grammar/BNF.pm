my class Actions { ... }

grammar Grammar::BNF {
    token TOP {
        \s* <rule>+ \s*
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

    method generate($source, :$name = 'BNFGrammar') {
        my $actions = Actions.new(:$name);
        my $ret = self.new.parse($source, :$actions).ast;
        return $ret.WHAT;
    }
}

my class Actions {
    has $.name = 'BNFGrammar';
    method TOP($/) {
        my $grmr := Metamodel::GrammarHOW.new_type(:$.name);
        $grmr.^add_method('TOP', EVAL 'token { <' ~ $<rule>[0].ast.key ~ '> }');
        for $<rule>.map(*.ast) -> $rule {
            $grmr.^add_method($rule.key, $rule.value);
        }
        $grmr.^compose;
        make $grmr;
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
