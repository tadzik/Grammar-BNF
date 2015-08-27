use Test;
use lib './lib';
use Slang::BNF;

plan 2;

bnf-grammar A::B {
<foo> ::= "bar"
};

ok(A::B.parse("bar"), "Parse succeeds");
ok(!A::B.parse("far"), "Parse fails when it doesn't match");

