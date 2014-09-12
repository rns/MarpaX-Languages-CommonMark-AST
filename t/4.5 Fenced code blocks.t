use 5.010;
use strict;
use warnings;
use Test::More;

use MarpaX::Languages::CommonMark::AST::Test;
 
plan tests => 1 * blocks;
 
run_is input => 'expected';

__END__
 
=== simple example with backticks
--- input filter
```
<
 >
```
--- expected
<pre><code>&lt;
 &gt;
</code></pre>

=== With tildes
--- input filter
~~~
<
 >
~~~
--- expected
<pre><code>&lt;
 &gt;
</code></pre>


