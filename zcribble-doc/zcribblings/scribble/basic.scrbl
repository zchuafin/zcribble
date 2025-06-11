#lang zcribble/manual
@(require "utils.rkt" (for-label (only-in zcribble/basic span-class)))

@(define (compat)
   @italic{For backward compatibility.})

@title[#:tag "basic"]{Compatibility Basic Functions}

@defmodule[zcribble/basic]{The @racketmodname[zcribble/basic]
compatibility library mostly just re-exports
@racketmodname[zcribble/base].}

@defproc[(span-class [style-name string?] [pre-content any/c] ...)
         element?]{

@compat[] Wraps the @tech{decode}d
@racket[pre-content] as an element with style @racket[style-name].}



@defproc[(itemize [itm (or/c whitespace? item/c)] ...
                  [#:style style (or/c style? string? symbol? #f) #f]) 
         itemization?]{

@compat[] Like @racket[itemlist], but whitespace strings among the
@racket[itm]s are ignored.}
