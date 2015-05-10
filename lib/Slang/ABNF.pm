
# Adaptation of ruoso++'s Grammar::EBNF slang code to Grammar::ABNF

use Grammar::ABNF;
use nqp;
use QAST:from<NQP>;
sub EXPORT(|) {
    my sub lk(Mu \h, \k) {
        nqp::atkey(nqp::findmethod(h, 'hash')(h), k)
    }
    role Slang::ABNF {
        rule package_declarator:sym<abnf-grammar> {
            <sym>
            :my $*name;
	    :my %*rules;
	    :my @*ruleorder;
            :my $*indent;
            <longname> { $*name := lk($/,'longname').Str }
            \{
            <rules=.FOREIGN_LANG('Grammar::ABNF::Slang', 'main_syntax')>
            \}
        }
    }
    role Slang::ABNF::Actions {
        method package_declarator:sym<abnf-grammar>(Mu $/ is rw) {
            # Bits extracted from rakudo/src/Perl6/Grammar.nqp (package_def)
            my $longname := $*W.dissect_longname(lk($/,'longname'));
            my $outer := $*W.cur_lexpad();
            # Locate any existing symbol. Note that it's only a match
            # with "my" if we already have a declaration in this scope.
            my $exists := 0;
            my @name = $longname.type_name_parts('package name', :decl(1));
            my $target_package :=
                $longname && $longname.is_declared_in_global()
                ?? $*GLOBALish
                !! $*OUTERPACKAGE;
            my $*PACKAGE = lk($/,"rules").made();
            $*W.install_package($/, @name, 'our', 'abnf-grammar',
                                $target_package, $outer, $*PACKAGE);
            $/.'make'(QAST::IVal.new(:value(1)));

        }
    }
    nqp::bindkey(%*LANG, 'MAIN',
                 %*LANG<MAIN>.HOW.mixin(%*LANG<MAIN>, Slang::ABNF));
    nqp::bindkey(%*LANG, 'MAIN-actions',
                 %*LANG<MAIN-actions>.HOW.mixin(%*LANG<MAIN-actions>,
                                                Slang::ABNF::Actions));
    nqp::bindkey(%*LANG, 'Grammar::ABNF::Slang', Grammar::ABNF::Slang);
    nqp::bindkey(%*LANG, 'Grammar::ABNF::Slang-actions',
                 Grammar::ABNF::Slang-actions);
    {}
}
