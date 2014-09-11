use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__
 
=== Simple emphasis
--- input filter
*foo bar*
--- expected
<p><em>foo bar</em></p>


