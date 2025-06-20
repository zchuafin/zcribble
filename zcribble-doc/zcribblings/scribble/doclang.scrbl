#lang zcribble/manual
@(require "utils.rkt")

@title[#:tag "doclang"]{Document Language}

@defmodulelang[zcribble/doclang2]{The @racketmodname[zcribble/doclang2]
language provides everything from @racket[racket/base], except that it
replaces the @racket[#%module-begin] form.

The @racketmodname[zcribble/doclang2] @racket[#%module-begin]
essentially packages the body of the module into a call to
@racket[decode], binds the result to @racket[doc], and exports
@racket[doc].

Any module-level form other than an expression (e.g., a
@racket[require] or @racket[define]) remains at the top level, and
the @racket[doc] binding is put at the end of the module. As usual, a
module-top-level @racket[begin] slices into the module top level.

For example:
@codeblock|{
#lang racket
(module example zcribble/doclang2
  "hello world, this is"
  " an example document")
(require 'example)
doc
}|

The behavior of @racketmodname[zcribble/doclang2] can be customized by
providing @racket[#:id], @racket[#:post-process], @racket[#:begin], and @racket[#:exprs]
arguments at the very beginning of the module.

@itemize[

@item{@racket[#:id] names the top-level documentation binding. By default, this
is @racket[doc].}

@item{@racket[#:post-process] processes the body of the module after
@racket[decode].  By default, this is @racket[values].}

@item{@racket[#:begin] prepends an additional sequence of expressions to the
beginning of the module's body outside of consideration for the document content.
For example, the default @racket[configure-runtime] submodule might be replaced
using @racket[#:begin], because using @racket[#:exprs] nests the replacement too
deeply to work as an override. By default, this is the empty sequence @racket[()].}

@item{@racket[#:exprs] prepends an additional sequence of expressions to the
beginning of the module's body, but after @racket[#:begin].  By default, this is the empty sequence
@racket[()].}

]

This example explicitly uses the defaults for all three keywords:

@codeblock|{
#lang racket
(module example zcribble/doclang2
  #:id doc
  #:post-process values
  #:exprs ()
  "hello world, this is an example document")
(require 'example)
doc
}|


The next toy example uses a different name for the documentation binding, and
also adds an additional binding with a count of the parts in the document:

@codeblock|{
#lang racket
(module example zcribble/doclang2
  #:id documentation
  #:post-process (lambda (decoded-doc)
                   (set! number-of-parts (length (part-parts decoded-doc)))
                   decoded-doc)
  #:exprs ((title "My first expression!"))

  (require zcribble/core
           zcribble/base)
  
  (define number-of-parts #f)
  (provide number-of-parts)
  (section "part 1")
  "hello world"
  (section "part 2")
  "this is another document")

(require 'example)
number-of-parts
documentation
}|


@history[#:changed "1.41" @elem{Added @racket[#:begin].}]}



@section{@racketmodname[zcribble/doclang]}
@defmodulelang[zcribble/doclang]{The @racketmodname[zcribble/doclang] language
provides most of the same functionality as @racketmodname[zcribble/doclang2], where the
configuration options are positional and mandatory.  The first three elements
in the @racket[#%module-begin]'s body must be the @racket[id],
@racket[post-process], and @racket[exprs] arguments.

Example:
@codeblock|{
#lang racket
(module* example zcribble/doclang
  doc
  values
  ()
  (require zcribble/base)
  (provide (all-defined-out))
  (define foo (para "hello again"))
  "hello world, this is an example document"
  (para "note the " (bold "structure")))

(module+ main
  (require (submod ".." example))
  (printf "I see doc is: ~s\n\n" doc)
  (printf "I see foo is: ~s" foo))
}|
}
