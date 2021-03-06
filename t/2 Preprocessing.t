use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__

=== Preprocessing
--- input filter
\tfoo\tbaz\t\tbim
--- expected
<pre><code>foo    baz        bim
</code></pre>

=== Preprocessing
--- input filter
    a\ta
    u\ta
--- expected
<pre><code>a    a
u    a
</code></pre>

