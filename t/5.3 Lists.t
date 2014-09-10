use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__
 
=== Lists
--- input filter
- foo
- bar
+ baz
--- expected
<ul>
<li>foo</li>
<li>bar</li>
</ul>
<ul>
<li>baz</li>
</ul>

=== Lists
--- input filter
1. foo
2. bar
3) baz
--- expected
<ol>
<li>foo</li>
<li>bar</li>
</ol>
<ol start="3">
<li>baz</li>
</ol>
