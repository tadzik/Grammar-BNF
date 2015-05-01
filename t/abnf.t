#!/usr/bin/env perl6

use v6;
use lib './lib';

use Test;

plan 12;

use Grammar::ABNF;

ok 1, 'We use Grammar::ABNF and we are still alive';

lives_ok { grammar G is Grammar::ABNF { token CRLF { "\n" } } },
    'We subclassed Grammar::ABNF';

my @simpletests = (

# Just some preliminary tests for now.  Grammars as keys and things they
# should successfully parse as values.

'foo = %x20
' => ' ',

'foo = %x20.20
' => '  ',

'foo = 4%x61-63
' => 'abca',

'foo = bar
bar = 1*%x61-63
' => 'abca',

'foo = bar phnord
phnord = "abc"
bar = "cde"
' => 'cdeabc'

);

for @simpletests[]:kv -> $c, $p (:key($g), :value($i)) {
    my $a = G.generate($g, :name("SimpleTestABNF$c"));
    is $a.WHAT.gist, "(SimpleTestABNF$c)", "Parse simple test #$c grammar";
    ok $a.parse($i), "Simple test grammar #$c parses material";
}
