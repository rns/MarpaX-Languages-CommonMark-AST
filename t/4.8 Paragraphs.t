use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__

=== simple example with two paragraphs
--- input filter
aaa

bbb
--- expected
<p>aaa</p>
<p>bbb</p>

=== Paragraphs can contain multiple lines, but no blank lines
--- input filter
aaa
bbb

ccc
ddd
--- expected
<p>aaa
bbb</p>
<p>ccc
ddd</p>

=== Multiple blank lines between paragraph have no effect
--- input filter
aaa


bbb
--- expected
<p>aaa</p>
<p>bbb</p>

=== Leading spaces are skipped
--- input filter
  aaa
 bbb
--- expected
<p>aaa
bbb</p>

=== Lines after the first may be indented any amount
--- input filter
aaa
             bbb
ccc
--- expected
<p>aaa
bbb
ccc</p>

=== the first line may be indented at most three spaces ...
--- input filter
   aaa
bbb
--- expected
<p>aaa
bbb</p>

=== ... or an indented code block will be triggered
--- input filter
    aaa
bbb
--- expected
<pre><code>aaa
</code></pre>
<p>bbb</p>

=== Final spaces are stripped before inline parsing
so a paragraph that ends with two or more spaces will not end with a hard line break
--- input filter
aaa     
bbb     
--- expected
<p>aaa<br />
bbb</p>

