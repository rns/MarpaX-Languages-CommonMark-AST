use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__
 
=== Example 4
--- input filter
***
---
___
--- expected
<hr />
<hr />
<hr />

=== Example 5
--- input filter
+++
--- expected
<p>+++</p>

    


