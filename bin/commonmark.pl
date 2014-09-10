# utility to be used with runtests.pl of CommonMark's test suite
use 5.010;
use strict;
use warnings;

use MarpaX::Languages::CommonMark::AST;

my $p = MarpaX::Languages::CommonMark::AST->new;

# try to get input from STDIN
my $input = join '', <>;

die "Usage: $0 < file" unless $input;

my $ast = $p->parse( $input );
my $html = $p->html( $ast );
print $html;
