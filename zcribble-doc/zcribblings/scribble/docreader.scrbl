#lang zcribble/doc
@(require zcribble/manual zcribble/bnf "utils.rkt")

@title[#:tag "docreader"]{Document Reader}

@defmodulelang[zcribble/doc]{The @racketmodname[zcribble/doc] language is
the same as @racketmodname[zcribble/doclang], except that
@racket[read-syntax-inside] is used to read the body of the module. In
other words, the module body starts in Scribble ``text'' mode instead
of S-expression mode.}
