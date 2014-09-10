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
    block ::= inline
    
    # 4 Leaf blocks
    leaf_block ::= horizontal_rule
    leaf_block ::= paragraph
    leaf_block ::= indented_code_block
    
    # 5 Container blocks
    container_block ::= list
    
    # 6 Inlines
    inline ::= 'to be written'
    
    # 4.1 Horizontal rules
    horizontal_rule ~ hr_indentation hr_chars [\n]
    horizontal_rule ~ hr_chars [\n]

    hr_indentation ~ ' ' | '  ' | '   '
    hr_chars       ~ stars | hyphens | underscores

    stars    ~ '***' star_seq
    star_seq ~ [\*]*

    hyphens    ~ '---' hyphen_seq
    hyphen_seq ~ [\-]*

    underscores    ~ '___' underscore_seq
    underscore_seq ~ [_]*

    # 4.4 Indented code blocks
    indented_code_block ::= indented_chunks

    indented_chunks     ::= indented_chunk blank_lines
    indented_chunks     ::= indented_chunk
    
    indented_chunk      ::= indented_chunk_line+
    indented_chunk_line ::= indented_code_block_spaces line

    indented_code_block_spaces ~ '    ' space_seq
    space_seq                  ~ [ ]*

    blank_lines ~ [\n]+
    
    # 4.8 Paragraphs
    paragraph ::= lines                     
    paragraph ::= line indented_chunk_line  # Example 10, Example 58

    lines     ::= line+
    line      ::= non_nl [\n]
    non_nl    ::= [^\n]+

    # 5.3 Lists
    list ::= ordered_list 
    list ::= bullet_list 
    
    ordered_list        ::= ordered_list_items [\n] [\n]
    ordered_list        ::= ordered_list_items
    
    ordered_list_items  ::= ordered_list_item+
    ordered_list_item   ::= ordered_list_marker list_marker_spaces line

    ordered_list_marker ~ digits '.'
    ordered_list_marker ~ digits ')'

    digits ~ [\d]+

    bullet_list        ::= bullet_list_items [\n] [\n] rank => 1
    bullet_list        ::= bullet_list_items
    
    bullet_list_items  ::= bullet_list_item+
    bullet_list_item   ::= bullet_list_marker list_marker_spaces line

    bullet_list_marker ~ '-' | '+' | '*'

    list_marker_spaces ~ ' ' | '  ' | '   ' | '    '    

END_OF_SOURCE
    } );

    return $self;
}

sub preprocess{
    my $input = shift;
    $input =~ s/\t/    /g;
    # todo: spec's "Line endings are replaced by newline characters (LF)."
    return $input;
}

sub parse {
    my ( $self, $input ) = @_;
    
    # 2.1 Preprocessing
    $input = preprocess $input;
    
    warn "parse input: '$input'";
    
    # get grammar, create recognizer and read input
    my $g = $self->{grammar};

    my $r = Marpa::R2::Scanless::R->new( { 
        grammar => $g,
        trace_terminals => 1,
    } );
    eval {$r->read(\$input)} || warn "Parse failure, progress report is:\n" . $r->show_progress;

    my $ast = $r->value;

    unless (defined $ast){
        warn "No parse";
        return;
    }
    
    if ( $r->ambiguity_metric() > 1 ){
        # gather parses
        my @asts;
        my $v = $ast;
        do {
            push @asts, ${ $v };
        } until ( $v = $r->value() );
        push @asts, ${ $v };
        # todo: 
        #   (1) to show ambiguities better
        #   (2) sort parses in descending order of relevance and use the first parse
        #       relevance: 
        #           - prefer lists to paragraphs

        # until the above is done,
        # just count alternatives and warn
        warn "Ambiguous parse: $#asts alternatives.";
        for my $i (0..$#asts){
            say "# Alternative ", $i+1, ":\n", Dump $asts[$i];
        }
    }
    
    return ${ $ast };
}

sub html{
    my ( $self, $ast ) = @_;

    warn "# html", Dump $ast;

    my $html = to_html( $ast );

    say $html;

    return $html;
}

sub to_html{
    my $ast = shift;
    if (ref $ast){
        my ($id, @children) = @$ast;
        if ($id eq 'document'){
            return join '', map { to_html( $_ ) } @children;
        }
        # 3 Blocks and Inlines
        elsif ($id eq 'block' 
            or $id eq 'leaf_block'
            or $id eq 'container_block'
            or $id eq 'inline'
            ){
            return join '', map { to_html( $_ ) } @children;
        }
        # 4.1 Horizontal rules
        elsif ($id eq 'horizontal_rule'){
            "<hr />\n";
        }
        # 4.4 Indented code blocks
        elsif ($id eq 'indented_code_block'){
            return "<pre><code>" . join ( "", map { to_html( $_ ) } @children ) . "</code></pre>\n"
        }
        elsif ($id eq 'indented_chunks'){
            return join ( '', map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'indented_chunk_line'){
            return join ( '', map { to_html( $_ ) } @children );
        }
        elsif ($id eq 'indented_chunk'){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'indented_code_block_spaces'){ # remove first 4 spaces
            return substr $ast->[1], 4;
        }
        # 5.3 Lists        
        elsif ($id eq 'list'){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'ordered_list'){
            return "<ol>\n" . join ( "", map { to_html( $_ ) } @children ) . "</ol>"
        }
        elsif ($id eq 'ordered_list_items'){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'ordered_list_item'){
            my $text = join ( "", map { to_html( $_ ) } @children );
            chomp $text;
            return "<li>" . $text . "</li>\n";
        }
        elsif ($id eq 'ordered_list_marker'){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'list_marker_spaces'){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'non_nl'){
            return join '', splice @$ast, 1;
        }
        elsif ($id eq 'blank_lines'){
            return "\n";
        }
        elsif ($id eq 'lines'){
            return join("", map { to_html( $_ ) } @children);
        }
        elsif ($id eq 'line'){
#            warn "to_html:\n$id\n", Dump \@children;
            return join('', map { to_html( $_ ) } @children );
#            return to_html( $children[0] );
        }
        elsif ($id eq 'paragraph'){
            my $text = join ( "\n", map { to_html( $_ ) } @children );
            chomp $text;
            return "<p>" . $text . "</p>\n";
        }
        else {
            warn "unknown", Dump $ast;
        }
    }
    else{ # scalar means literal
        return $ast;
    }
}

1;

__END__
