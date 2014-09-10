use 5.010;
use strict;
use warnings;
use Test::More;

use_ok 'MarpaX::Languages::CommonMark::AST';

my $p = new_ok 'MarpaX::Languages::CommonMark::AST';

isa_ok $p, 'MarpaX::Languages::CommonMark::AST';

done_testing;
