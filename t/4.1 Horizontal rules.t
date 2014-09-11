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

=== One to three spaces indent are allowed:
--- input filter
 ***
  ***
   ***
--- expected
<hr />
<hr />
<hr />

=== Four spaces is too many
--- input filter
    ***
--- expected
<pre><code>***
</code></pre>

=== Four spaces is too many
--- input filter
Foo
    ***
--- expected
<p>Foo
***</p>

=== More than three characters may be used:
--- input filter
_____________________________________
--- expected
<hr />

=== Spaces are allowed between the characters
--- input filter
 - - -
--- expected
<hr />

=== Spaces are allowed between the characters
--- input filter
 **  * ** * ** * **
--- expected
<hr />

=== Spaces are allowed between the characters
--- input filter
-     -      -      -
--- expected
<hr />

=== Spaces are allowed at the end.
--- input filter
- - - -    
--- expected
<hr />

=== However, no other characters may occur at the end or the beginning.
--- input filter
_ _ _ _ a

a------
--- expected
<p>_ _ _ _ a</p>
<p>a------</p>

=== It is required that all of the non-space characters be the same.
--- input filter
 *-*
--- expected
<p><em>-</em></p>
 
=== Horizontal rules do not need blank lines before or after
--- input filter
- foo
***
- bar
--- expected
<ul>
<li>foo</li>
</ul>
<hr />
<ul>
<li>bar</li>
</ul>

=== Horizontal rules can interrupt a paragraph:
--- input filter
Foo
***
bar
--- expected
<p>Foo</p>
<hr />
<p>bar</p>

=== a setext header, not a paragraph followed by a horizontal rule:
--- input filter
Foo
---
bar
--- expected
<h2>Foo</h2>
<p>bar</p>

=== the horizontal rule is preferred
When both a horizontal rule and a list item are possible interpretations of a line
--- input filter
* Foo
* * *
* Bar
--- expected
<ul>
<li>Foo</li>
</ul>
<hr />
<ul>
<li>Bar</li>
</ul>

=== a horizontal rule in a list item
--- input filter
- Foo
- * * *
--- expected
<ul>
<li>Foo</li>
<li><hr /></li>
</ul>

