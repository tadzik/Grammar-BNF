my class ABNF-Actions {...};

grammar Grammar::ABNF {

    token TOP {
# TODO deal with indentation and folded rules
#        \s*? (<!after " ">\s*)
#        { $*indent = $/[0].chars; }
        <rulelist> \s*
    }

    # Rule names are directly from RFC 5234 Section 4 for this section
    token rulelist {
        [ <rule> | [ <.c-wsp>* <.c-nl> ] ]+
    }

    # Altered for indenting behavior
    regex rule {
        # New rules can start if they are not indented more than the last rule
#        ( <.WSP>**{0..$*indent} )
        <rulename> <defined-as> <elements> <.c-nl>
        # ratchet in the indent
#        { $*indent = $0.chars }
    }

    # This is not in the RFC but helps keep things DRY
    token name {
        # TODO: if the uppercase rule exists use it.
        :i (<+alpha><+alnum +[-]>+)
    }

    token rulename {
        [ '<' <name> '>' ] | <name>
    }

    token defined-as {
        <.c-wsp>* ("=" | "=/") <.c-wsp>*
    }

    token elements {
        <alternation> <.c-wsp>*
    }

    # We just do this the way the RFC does, though unnecessary
    regex c-wsp {
        <.WSP> | [ <.c-nl> <.WSP> ]
    }

    regex c-nl {
        [ <.comment> | <.CRLF> ]
    }

    token comment {
        ';' ( <+WSP +VCHAR> )* <.CRLF>
    }

    regex alternation {
        <concatenation>+ % [ <.c-wsp>* "/" <.c-wsp>* ]
    }

    regex concatenation {
        <repetition>+ % <.c-wsp>+
    }

    regex repetition {
        <repeat>? <element>
    }

    token repeat {
        [$<min>=[<.DIGIT>+]]? [$<star>='*']? [$<max>=[<.DIGIT>+]]? {
            X::Syntax::Regex::MalformedRange.new.throw
                if ($/<min> // 0) > ($/<max> // Inf);
        }
    }

    token element {
        <rulename> || <group> | <option> | <char-val> | <num-val> | <prose-val>
    }

    token group {
        "(" <.c-wsp>* <alternation> <.c-wsp>* ")"
    }

    token option {
        "[" <.c-wsp>* <alternation> <.c-wsp>* "]"
    }

    token char-val {
        <.DQUOTE> (<[\x20..\x21] + [\x23..\x7E]>*) <.DQUOTE>
    }

    token num-val {
        "%" [ <bin-val> | <dec-val> | <hex-val> ]
    }

    token bin-val { "b" [ [ $<val>=[<.BIT>+] ]+ % "." |
                            $<min>=[<.BIT>+] "-" $<max>=[<.BIT>+] ]
                  }

    token dec-val { "d" [ [ $<val>=[<.DIGIT>+] ]+ % "." |
                            $<min>=[<.DIGIT>+] "-" $<max>=[<.DIGIT>+] ]
                  }

    token hex-val { "x" [ [ $<val>=[<.HEXDIG>+] ]+ % "." |
                            $<min>=[<.HEXDIG>+] "-" $<max>=[<.HEXDIG>+] ]
                  }

    token prose-val {
        "<" (<[\x20..\x3D] + [\x3F..\x7E]>*) ">"
    }

    # These should be in a separate grammar as they are often referenced.
    # RFC 5234 Appendix B.1. "Core Rules"
    token ALPHA       { <[\x41..\x5a] + [\x61..\x7a]> }
    token BIT         { <[\x30 \x31]> }
    token CHAR        { <[\x01..\x7f]> }
    token CR          { \x0d }
    token CRLF        { \x0d \x0a }
    token CTL         { <[\x00..\x1f] + [\x7f]> }
    token DIGIT       { <[\x30..\x39]> }
    token DQUOTE      { \x22 }
    token HEXDIG      { <+ DIGIT + [\x41..\x5a] + [\x61..\x7a]> }
    token HTAB        { \x09 }
    token LWSP        { [ <.WSP> | <.CRLF> <.WSP> ]* }
    token LF          { \x0a }
    token OCTET       { <[\x00..\xff]> }
    token SP          { \x20 }
    token VCHAR       { <[\x21..\x7e]> }
    token WSP         { <+SP + HTAB> }

    # Provide a parse with defaults and also define our per-parse scope.
    method parse(|c) {
        my %*rules;
	my @*ruleorder;
        my $*indent;
	my $*name = c<name> // 'ABNF-Grammar';
	nextsame if (c<actions>);
	nextwith(|c, :actions(ABNF-Actions));
    }

    # We may want to rename this given jnthn's Grammar::Generative
    method generate(|c) {
        my $res = self.parse(|c);
        fail("parse *of* an ABNF grammar definition failed.") unless $res;
	return $res.ast;
    }

}

my class ABNF-Actions {

    method TOP($/) {
        my $grmr := Metamodel::GrammarHOW.new_type(:name($*name));
        # When /<$f>/ and /<@f>/ are secure and reliable we might
        # be able to avoid the EVALs.  Unless thay do not constant-fold,
        # or remain impermeable to grabbing subrules from inside them.
        my $top = EVAL 'token { <' ~ @*ruleorder[0] ~ '> }';
        $top.set_name('TOP'); # There are two name slots IIRC.
        $grmr.^add_method('TOP', $top);
        for %*rules.pairs -> $rule {
            my $r = EVAL 'token { ' ~ $rule.value ~ ' }';
            $r.set_name($rule.key);
            $grmr.^add_method($rule.key, $r);
        }
        $grmr.^compose;
        make $grmr;
    }

    method rule($/) {
        my $rulename = $/<rulename>.ast;
        my $ruleval = $/<elements><alternation>.ast;
        if (%*rules{$rulename}:exists) {
            if $/<defined-as> eq '=' {
                X.Redeclaration.new(:symbol($rulename)
                                    :what('Regex')
                                    :postfix('in ABNF definitions')).throw;
            }
	    %*rules{$rulename} ~= " | $ruleval";
        }
        else {
            push @*ruleorder, $rulename;
	    %*rules{$rulename} = "$ruleval";
        }
    }

    method rulename($/) {
        make $/<name>.lc
    }

    method alternation($/) {
        make join(" | ", $/<concatenation>[]».ast)
    }

    method concatenation($/) {
        make join(" ", $/<repetition>[]».ast)
    }

    method repetition($/) {
        make $/<element>.ast unless $/<repeat>.defined;
        my $repeat = '';
	if $/<repeat><star> {
            my $min = $/<repeat><min> // 0;
            my $max = $/<repeat><max> // '*';
	    $repeat = '**' ~ $min ~ ".." ~ $max;
	}
	elsif $/<repeat><min> {
            $repeat ~= '**' ~ $/<repeat><min>;
	}
        make "[[ " ~ $/<element>.ast ~ " ]" ~ "$repeat ]";
    }

    method element($/) {
        # Only one of these will exist
        if $/<rulename> {
            make "<" ~ $/<rulename>.ast ~ ">";
	}
        else {
            make $/<group option char-val
                    num-val prose-val>.first(*.defined).ast;
        }
    }

    method group($/) {
        make "[ " ~ $/<alternation>.ast ~ " ]";
    }

    method option($/) {
        make "[ " ~ $/<alternation>.ast ~ " ]?";
    }

    method char-val($/) {
        # Don't EVAL metachars.  I do not curently trust /$foo/ as it still
        # needs work IIRC.  Later we should be able to do something like:
        #
        # my $f = $/[0]; make rx:ratchet/$f/;
        #
        # So here is the brute force interim solution.
        #
	# The .ords may get deprecated with NFG, and synthetic-leak-refusal
        # would cause trouble here.  Really we need to use the encoding
        # of the source and re-encode it.  But it will be 8-bit for most uses,
        # so deal with it later.
        make "[" ~  (~$/[0]).ords.fmt(" \\x%x") ~ " ]";
    }

    method num-val($/) {
        # Only one of these will exist
        make $/<bin-val dec-val hex-val>.first(*.defined).ast;
    }

    # For all the num-vals, the RFC does not put limits on the number of
    # digits nor the codepoint values (You can use ABNF on unicode if you
    # really want to, if you adjust the "core rules" in B.1.)  We could
    # just shove the strings back into the perl6 regexps, but instead we
    # write it in a way that is convenient to customize/sanitize.
    my sub numval ($m, &rad2num) {
        if $m<val> {
            join(" ", "[", $m<val>[].map({ rad2num(~$_).fmt('\\x%x') }), "]")
        }
        else {
            sprintf('<[\\x%x..\\x%x]>', $m<min max>.map: { rad2num(~$_) })
        }
    }

    method bin-val($/) {
        make numval($/, { :2($^n) });
    }

    method dec-val($/) {
        make numval($/, { :10($^n) });
    }

    method hex-val($/) {
        make numval($/, { :16($^n) });
    }

    method prose-val($/) {
        make qq:to<EOCODE>;
        \{
           X::NYI.new(:feature(\$/[0].fmt(Q:to<EOERR>) ~ 'Such a mixin')).throw
        \}
            This ABNF Grammar requires you to mix in custom code to do
            the following:
                %s
            ...which you may have to write yourself.
            EOERR
        EOCODE
    }
}
