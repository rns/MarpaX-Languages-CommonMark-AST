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
    
    # Markdown
    document ::= block+
    
    # 3.2 Container blocks and leaf blocks
    block ::= leaf_block
    block ::= container_block
    
    # 4 Leaf blocks
    leaf_block ::= horizontal_rule
    leaf_block ::= ATX_header
    leaf_block ::= setext_header
    leaf_block ::= indented_code_block
    leaf_block ::= fenced_code_block
    # ...
    leaf_block ::= paragraph
    
    # 4.1 Horizontal rules
    horizontal_rule ::= hr_marker [\n]
    
    hr_marker ~ hr_indentation hr_chars
    hr_marker ~ hr_chars
    
    hr_indentation ~ ' ' | '  ' | '   '
    hr_chars ~ stars | hyphens | underscores

    stars ~ star_item star_item star_item
    stars ~ star_item star_item star_item star_item_seq
    star_item_seq ~ star_item+
    star_item ~ star_seq zero_or_more_spaces
    star_item ~ star_seq
    star_seq ~ star
    star_seq ~ star star
    star ~ '*'

    hyphens ~ hyphen_item hyphen_item hyphen_item
    hyphens ~ hyphen_item hyphen_item hyphen_item hyphen_item_seq
    hyphen_item_seq ~ hyphen_item+
    hyphen_item ~ hyphen_seq zero_or_more_spaces
    hyphen_item ~ hyphen_seq
    hyphen_seq ~ hyphen
    hyphen_seq ~ hyphen hyphen
    hyphen ~ '-'

    underscores ~ underscore_item underscore_item underscore_item
    underscores ~ underscore_item underscore_item underscore_item underscore_item_seq
    underscore_item_seq ~ underscore_item+
    underscore_item ~ underscore_seq zero_or_more_spaces
    underscore_item ~ underscore_seq
    underscore_seq  ~ underscore
    underscore_seq  ~ underscore underscore
    underscore ~ '_'

    zero_or_more_spaces ~ [ ]*
    
    # 4.2 ATX headers
    ATX_header ::= ATX_header_marker ([ ]) line
    
    ATX_header_marker ~ '#'
    ATX_header_marker ~ '##'
    ATX_header_marker ~ '###'
    ATX_header_marker ~ '####'
    ATX_header_marker ~ '#####'
    ATX_header_marker ~ '######'
    
    # 4.3 Setext headers
    setext_header ::= non_nl ([\n]) setext_header_underline
    setext_header_underline ::= setext_header_hyphens
    setext_header_underline ::= setext_header_equals_sign
    setext_header_hyphens ~ [\-]+
    setext_header_equals_sign ~ [=]+
    
    # 4.4 Indented code blocks
    indented_code_block ::= indented_chunks

    indented_chunks ::= indented_chunk blank_lines
    indented_chunks ::= indented_chunk
    
    indented_chunk ::= indented_chunk_line+
    indented_chunk_line ::= indented_code_block_spaces line

    indented_code_block_spaces ~ '    ' zero_or_more_spaces

    # 4.5 Fenced code blocks
    fenced_code_block ::= code_fence_backticks fenced_code_block_content code_fence_backticks
    fenced_code_block ::= code_fence_tildes fenced_code_block_content code_fence_tildes
    fenced_code_block_content ::= line+
    code_fence_backticks ~ '`' | '``' | '```'
    code_fence_tildes ~ '~' | '~~' | '~~~'
    
    # 4.6 HTML blocks
    # 4.7 Link reference definitions

    # 4.8 Paragraphs

    paragraph ::= paragraph_lines blank_lines
    paragraph_lines ::= paragraph_line+
    paragraph_line ::= paragraph_line_items
    paragraph_line_items ::= paragraph_line_item+
    
    # special cases
    paragraph ::= paragraph_line indented_chunk_line  # Example 10, Example 58
    
    # A sequence of non-blank lines that cannot be interpreted 
    # as other kinds of blocks forms a paragraph.
    # not a horizontal rule
    paragraph_line_item ::= hr_marker line # can start from horizontal line marker
                                           # only if followed by a non-newline
    # not an ATX_header
    
    # not an setext_header
    # not an indented_code_block
    # not a fenced_code_block
    
    # The contents of the paragraph are the result of parsing 
    # the paragraph’s raw content as inlines
    paragraph_line_item ::= emphasis
    
    # not a list
    paragraph_line ::= list_marker [^ ] line # can start from a list marker
                                             # only if followed by a non-space
    paragraph_line ::= list_marker [\n]      # or a newline

    list_marker ::= bullet_list_marker_hyphen
    list_marker ::= bullet_list_marker_plus
    list_marker ::= bullet_list_marker_star
    list_marker ::= ordered_list_marker_period
    list_marker ::= ordered_list_marker_bracket

    # 4.9 Blank lines
    blank_lines ~ [\n]*

    # 5 Container blocks
    container_block ::= list

    # 5.1 Block quotes

    # 5.2 List items
    # 5.3 Lists
    list ::= ordered_list 
    list ::= bullet_list 
    
    ordered_list ::= ordered_list_items_period [\n] [\n]
    ordered_list ::= ordered_list_items_period
    ordered_list ::= ordered_list_items_bracket [\n] [\n]
    ordered_list ::= ordered_list_items_bracket
    
    ordered_list_items_period ::= ordered_list_item_period+
    ordered_list_item_period ::= ordered_list_marker_period (list_marker_spaces) line
    ordered_list_item_period ::= ordered_list_marker_period (list_marker_spaces) horizontal_rule

    ordered_list_items_bracket ::= ordered_list_item_bracket+
    ordered_list_item_bracket ::= ordered_list_marker_bracket (list_marker_spaces) line
    ordered_list_item_bracket ::= ordered_list_marker_bracket (list_marker_spaces) horizontal_rule

    ordered_list_marker_period ~ digits '.'
    ordered_list_marker_bracket ~ digits ')'

    digits ~ [0-9]+

    bullet_list ::= bullet_list_items [\n] [\n] rank => 1
    bullet_list ::= bullet_list_items
    
    bullet_list_items ::= bullet_list_items_hyphen
    bullet_list_items ::= bullet_list_items_plus
    bullet_list_items ::= bullet_list_items_star

    bullet_list_items_hyphen ::= bullet_list_item_hyphen+
    bullet_list_item_hyphen ::= (bullet_list_marker_hyphen) (list_marker_spaces) line
    bullet_list_item_hyphen ::= (bullet_list_marker_hyphen) (list_marker_spaces) horizontal_rule
    bullet_list_marker_hyphen ~ '-'

    bullet_list_items_plus ::= bullet_list_item_plus+
    bullet_list_item_plus ::= (bullet_list_marker_plus) (list_marker_spaces) line
    bullet_list_item_plus ::= (bullet_list_marker_plus) (list_marker_spaces) horizontal_rule
    bullet_list_marker_plus  ~ '+'

    bullet_list_items_star ::= bullet_list_item_star+
    bullet_list_item_star ::= (bullet_list_marker_star) (list_marker_spaces) line
    bullet_list_item_star ::= (bullet_list_marker_star) (list_marker_spaces) horizontal_rule
    bullet_list_marker_star ~ '*'

    list_marker_spaces ~ ' ' | '  ' | '   ' | '    '    
    
    # 6 Inlines
#    inline ::= 'no block can contain any inline, so this is not needed yet'

    # 6.1 Backslash escapes
    # 6.2 Entities
    # 6.3 Code span
    
    # 6.4 Emphasis and strong emphasis
    emphasis ::= (emphasis_star) emphasized (emphasis_star)
    emphasis_star ~ '*'
    emphasized ~ [^*]+
    
    # 6.5 Links
    # 6.6 Images
    # 6.7 Autolinks
    # 6.8 Raw HTML
    # 6.9 Hard line breaks
    # 6.10 Soft line breaks
    # 6.11 Strings

    # line of non-newlines up to an including newline
    line ::= non_nl [\n]
    non_nl ~ [^\n]+

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
#        trace_terminals => 99,
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
        warn "Ambiguous parse: ", $#asts + 1, " alternatives.";
        for my $i (0..$#asts){
            say "# Alternative ", $i+1, ":\n", Dump $asts[$i];
        }
    }
    
    return ${ $ast };
}

sub html{
    my ( $self, $ast ) = @_;

#    warn "# html", Dump $ast;

    my $html = to_html( $ast );

#    say $html;

    return $html;
}

sub dump_node { 
    my ($id, @children) = @_;
    return "# <$id> " . ( @children ? Dump \@children : "\n" ); 
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
            ){
            return join '', map { to_html( $_ ) } @children;
        }
        # 4.1 Horizontal rules
        elsif ($id eq 'horizontal_rule'){
            return "<hr />\n";
        }
        # when <hr_marker> occurs as part of a paragraph line
        elsif ($id eq 'hr_marker'){
            return join ( '', map { to_html( $_ ) } @children );
        }
        # 4.2 ATX headers
        elsif ($id eq 'ATX_header'){
#           warn dump_node $id, @children;
            my $level = length $children[0]->[1];
            my $text = $children[1]->[1]->[1];
            chomp $text;
            return "<h$level>$text</h$level>\n";
        }
        # 4.3 Setext headers
        elsif ($id eq 'setext_header'){
#            warn dump_node $id, @children;
            my $text = $children[0]->[1];
            my $underline = $children[1]->[1]->[0];
            my $level;
            if ($underline eq 'setext_header_hyphens'){
                $level = 2;
            }
            elsif ($underline eq 'setext_header_equals_sign'){
                $level = 1;
            }
            return "<h$level>$text</h$level>";
        }
        elsif ($id eq 'setext_header_underline'){
            return join ( '', map { to_html( $_ ) } @children );
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
        # 4.8 Paragraphs
        elsif ($id eq 'paragraphs'){
            return join ( "\n", map { to_html( $_ ) } @children );
        }
        elsif ($id eq 'paragraph'){
#            warn dump_node $id, @children;
            my $text = join ( "\n", map { to_html( $_ ) } @children );
            $text =~ s/\n+$//;
#            warn "# $id\'s text:\n'$text'";
            return "<p>" . $text . "</p>\n";
        }
        elsif ($id eq 'paragraph_lines'){
            return join("", map { to_html( $_ ) } @children);
        }
        elsif ($id eq 'paragraph_line'){
            return join('', map { to_html( $_ ) } @children );
        }
        elsif ($id eq 'paragraph_line_items'){
            return join('', map { to_html( $_ ) } @children );
        }
        elsif ($id eq 'paragraph_line_item'){
            return join('', map { to_html( $_ ) } @children );
        }
        # 5.3 Lists        
        elsif ($id eq 'list'){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'ordered_list'){
            # get start marker and set list start as needed
#           warn "start marker:", Dump $children[0]->[1]->[1]->[1];
            my $start_marker = substr $children[0]->[1]->[1]->[1], 0, -1;
            return "<ol" . ($start_marker > 1 ? qq{ start="$start_marker"} : '') . ">\n" 
                . join ( "", map { to_html( $_ ) } @children ) 
                . "</ol>\n"
        }
        elsif ($id eq 'bullet_list'){
            return "<ul>\n" . join ( "", map { to_html( $_ ) } @children ) . "</ul>\n"
        }
        elsif ($id =~ /^ordered_list_items/
            or $id =~ /^bullet_list_items/){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id =~ /^ordered_list_item/
            or $id =~ /^bullet_list_item/){
            my $text = join ( "", map { to_html( $_ ) } @children );
            chomp $text;
            return "<li>" . $text . "</li>\n";
        }
        elsif ($id =~ /^ordered_list_marker/){
            return '';
        }
        elsif ($id =~ /^bullet_list_marker/){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'list_marker_spaces'){
            return join ( "", map { to_html( $_ ) } @children )
        }
        elsif ($id eq 'non_nl'){
            return join("", map { to_html( $_ ) } @children);
        }
        elsif ($id eq 'blank_lines'){
            return "\n";
        }
        # 6 Inlines
        elsif ($id eq 'inline'){
            return join("", map { to_html( $_ ) } @children);
        }
        # 6.4 Emphasis and strong emphasis
        elsif ($id eq 'emphasis'){
            return "<em>" . $children[0]->[1] . "</em>";
        }
        
        elsif ($id eq 'lines'){
            return join("", map { to_html( $_ ) } @children);
        }
        elsif ($id eq 'line'){
            return join('', map { to_html( $_ ) } @children );
        }
        else {
            warn "# Unknown node!\n", dump_node $id, @children;
        }
    }
    else{ # scalar means literal
        return $ast;
    }
}

1;

__END__
