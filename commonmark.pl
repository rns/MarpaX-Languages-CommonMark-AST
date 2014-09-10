# utility to be used with runtests.pl of CommonMark's test suite
use 5.010;
use strict;
use warnings;

use MarpaX::Languages::CommonMark::AST;

my $p = MarpaX::Languages::CommonMark::AST->new;

# try to get input from STDIN
my $input = join '', <>;

# no input from STDIN, use our own
unless ($input){
    $input = <<EOI;
***
---
___
+++

===

--
**
__

 ***
  ***
   ***
    ***

Foo
    ***

    <a/>
    *hi*

    - one

    a simple
      indented code block

EOI
}

=pod horizontal rule tests

_____________________________________

 - - -

 **  * ** * ** * ** 
=cut

#say Dump $ast;

my $ast = $p->parse( $input );

my $html = $p->html( $ast );
print $html;

__END__
