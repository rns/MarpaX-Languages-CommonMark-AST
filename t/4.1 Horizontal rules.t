use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__
 
=== Horizontal lines
--- input filter
***
---
___
--- expected
<hr />
<hr />
<hr />

=== Wrong characters
--- input filter
+++
--- expected
<p>+++</p>

=== Wrong characters
--- input filter
q{===}
--- expected
<p>===</p>

=== Not enough characters
--- input filter
--
**
__
--- expected
<p>--
**
__</p>



