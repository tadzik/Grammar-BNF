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

    token rule-name {
        <-[>]>+
    }
}
