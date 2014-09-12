use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__
 
=== Simple headers
--- input filter
Foo *bar*
q{=========}

Foo *bar*
q{---------}
--- expected
<h1>Foo <em>bar</em></h1>
<h2>Foo <em>bar</em></h2>
