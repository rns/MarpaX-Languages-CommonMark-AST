package MarpaX::Languages::CommonMark::AST;

use 5.010;
use strict;
use warnings;

use YAML;
use Data::Dumper;

use Marpa::R2 2.090; # for parse()

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;
    
    $self->{grammar} = Marpa::R2::Scanless::G->new( { 
        source => \(<<'END_OF_SOURCE'),
:default ::= action => [ name, value ]
lexeme default = action => [ name, value ] latm => 1

    document ::= block+

    block ::= leaf_block
    block ::= container_block
    block ::= blank_line
    block ::= inline

    leaf_block ::= horizontal_rule
    leaf_block ::= paragraph
    leaf_block ::= indented_code_block

    horizontal_rule ~ hr_indentation hr_chars [\n]
    horizontal_rule ~ hr_chars [\n]

    hr_indentation ~ ' ' | '  ' | '   '
    hr_chars       ~ stars | hyphens | underscores

    stars ~ '***' star_seq
    star_seq ~ [\*]*

    hyphens ~ '---' hyphen_seq
    hyphen_seq ~ [\-]*

    underscores ~ '___' underscore_seq
    underscore_seq ~ [_]*

    paragraph ::= lines
    paragraph ::= line indented_chunk_line # Example 10, Example 58
    lines     ::= line+
    line      ::= non_nl [\n]
    non_nl    ::= [^\n]+

    blank_line ~ [\n]

    indented_code_block ::= indented_chunks

    indented_chunks     ::= indented_chunk blank_lines
    indented_chunk      ::= indented_chunk_line+
    indented_chunk_line ::= indented_code_block_spaces line

    indented_code_block_spaces ~ '    ' space_seq
    space_seq ~ [ ]*

    blank_lines ~ [\n]+

    container_block ::= 'to be written'

    inline ::= 'to be written'

END_OF_SOURCE
    } );

    return $self;
}

sub parse {
    my ( $self, $input ) = @_;

    my $g = $self->{grammar};

    my $r = Marpa::R2::Scanless::R->new( { 
        grammar => $g,
    #    trace_terminals => 99
    } );
    eval {$r->read(\$input)} || die "Parse failure, progress report is:\n" . $r->show_progress;

    my $ast;

    if ( $r->ambiguity_metric() > 1 ){
        say "Ambiguous parse, use Marpa::R2::ASF, now dumping alternatives:" ;
        # for starters, use alternative 1
        # try to show ambiguitties better
        $ast = ${ $r->value };
        my $v = $ast;
        my $i = 1;
        do {
            say "# Alternative ", $i++, ":", Dump $v;
        } until ( $v = ${ $r->value() } );
        say Dump $v;
        say "$i alternatives.";
    }
    else{
        $ast = ${ $r->value };
    }
    
    return $ast;
}

sub html{
    my ( $self, $ast ) = @_;
    return to_html( $ast );
}

sub to_html{
    my $ast = shift;
    if (ref $ast){
        my ($id, @children) = @$ast;
        if ($id eq 'document'){
            join '', map { to_html( $_ ) } @children;
        }
        elsif ($id eq 'block' 
            or $id eq 'leaf_block'){
            to_html( @children );
        }
        elsif ($id eq 'horizontal_rule'){
            "<hr />\n";
        }
        elsif ($id eq 'indented_code_block'){
            return "<pre><code>" . join ( "\n", map { to_html( $_ ) } @children ) . "</code></pre>\n"
        }
        elsif ($id eq 'indented_chunks'){
            return join ( '', map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'indented_chunk_line'){
            return join ( '', map { to_html( $_ ) } @children ) . "\n";
        }
        elsif ($id eq 'indented_chunk'){
            return join ( '', map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'indented_code_block_spaces'){ # remove first 4 spaces
            return substr $ast->[1], 4;
        }
        
        elsif ($id eq 'non_nl'){
            return join '', splice @$ast, 1;
        }
        elsif ($id eq 'blank_lines'){
            return "\n";
        }
        elsif ($id eq 'blank_line'){
            return "\n";
        }
        elsif ($id eq 'blank_line_seq'){
            say "$id: ", Dumper $ast;
            return "\n";
        }
        elsif ($id eq 'line'){
            return join '', map { to_html( $_ ) } @children;
        }
        elsif ($id eq 'paragraph'){
            return "<p>" . join ( "\n", map { to_html( $_ ) } @children ) . "</p>\n";
        }
        else {
            warn "unknown", Dump $ast;
        }
    }
}

1;

__END__
