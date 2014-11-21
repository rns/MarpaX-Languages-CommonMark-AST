MarpaX-Languages-CommonMark-AST
===============================

BNF-based implementation of spec.commonmark.org using Marpa::R2, now at its inception.

The initial plan is to get basic tests in most spec sections passing, thus producing a preliminary
version of the single grammar used for both specification and (mostly) syntax-driven
(aka declarative) parsing.

Note: The current implementation ignores nesting blocks (e.g. in lists or blockquotes).
