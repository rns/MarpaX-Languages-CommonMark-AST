use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__

=== indented code block
--- input filter
    a simple
      indented code block
--- expected
<pre><code>a simple
  indented code block
</code></pre>

=== An indented code block cannot interrupt a paragraph.
--- input filter
Foo
    bar
--- expected
<p>Foo
bar</p>
