#lang zcribble/doc
@(require "mz.rkt" (for-label racket/syntax))

@title[#:tag "syntax-util"]{Syntax Utilities}

@(define the-eval (make-base-eval))
@(the-eval '(require racket/syntax))
@(the-eval '(require (for-syntax racket/base racket/syntax)))

@note-lib-only[racket/syntax]


@;{----}

@section{Creating formatted identifiers}

@defproc[(format-id [lctx (or/c syntax? #f)]
                    [fmt string?]
                    [v (or/c string? symbol? keyword? char? number?
                             (syntax/c (or/c string? symbol? keyword? char? number?)))] ...
                    [#:source src (or/c syntax? #f) #f]
                    [#:props props (or/c syntax? #f) #f]
                    [#:cert ignored (or/c syntax? #f) #f]
                    [#:subs? subs? boolean? #f]
                    [#:subs-intro subs-introducer
                                  (-> syntax? syntax?)
                                  (if (syntax-transforming?) syntax-local-introduce values)])
         identifier?]{

Like @racket[format], but produces an identifier using @racket[lctx]
for the lexical context, @racket[src] for the source location, and
@racket[props] for the properties. An argument supplied with
@racket[#:cert] is ignored. (See @racket[datum->syntax].)

The format string must use only @litchar{~a} placeholders.
Syntax objects in the argument list are automatically unwrapped
(e.g., identifiers will be automatically converted to symbols).

@examples[#:eval the-eval
(define-syntax (make-pred stx)
  (syntax-case stx ()
    [(make-pred name)
     (format-id #'name "~a?" (syntax-e #'name))]))
(make-pred pair)
(eval:error (make-pred none-such))
(define-syntax (better-make-pred stx)
  (syntax-case stx ()
    [(better-make-pred name)
     (format-id #'name #:source #'name
                "~a?" (syntax-e #'name))]))
(eval:error (better-make-pred none-such))
]

(Scribble doesn't show it, but the DrRacket pinpoints the location of
the second error but not of the first.)

If @racket[subs?] is @racket[#t], then a @racket['sub-range-binders]
syntax property is added to the result that records the position of
each identifier in the @racket[v]s. The @racket[subs-intro] procedure
is applied to each identifier, and its result is included in the
sub-range binder record. This property value overrides a
@racket['sub-range-binders] property copied from @racket[props].

@examples[#:eval the-eval
(syntax-property (format-id #'here "~a/~a-~a" #'point 2 #'y #:subs? #t)
                 'sub-range-binders)
]

@history[#:changed "7.4.0.5" @elem{Added the @racket[#:subs?] and
@racket[#:subs-intro] arguments.}
         #:changed "8.7.0.7" @elem{Allowed @racket[v] to be a syntax object
wrapping a string, a keyword, a character, or a number.}]
}

@defproc[(format-symbol [fmt string?]
                        [v (or/c string? symbol? keyword? char? number?
                                 (syntax/c (or/c string? symbol? keyword? char? number?)))] ...)
         symbol?]{

Like @racket[format], but produces a symbol. The format string must
use only @litchar{~a} placeholders.
Syntax objects in the argument list are automatically unwrapped
(e.g., identifiers will be automatically converted to symbols).

@examples[#:eval the-eval
  (format-symbol "make-~a" 'triple)
]

@history[#:changed "8.7.0.7" @elem{Allowed @racket[v] to be a syntax object
wrapping a string, a keyword, a character, or a number.}]
}


@;{----}

@section{Pattern variables}

@defform[(define/with-syntax pattern stx-expr)
         #:contracts ([stx-expr syntax?])]{

Definition form of @racket[with-syntax]. That is, it matches the
syntax object result of @racket[stx-expr] against @racket[pattern] and
creates pattern variable definitions for the pattern variables of
@racket[pattern].

@examples[#:eval the-eval
(define/with-syntax (px ...) #'(a b c))
(define/with-syntax (tmp ...) (generate-temporaries #'(px ...)))
#'([tmp px] ...)
(define/with-syntax name #'Alice)
#'(hello name)
]
}


@;{----}

@section{Error reporting}

@defparam[current-syntax-context stx (or/c syntax? #f)]{

The current contextual syntax object, defaulting to @racket[#f].  It
determines the special form name that prefixes syntax errors created
by @racket[wrong-syntax].
}

@defproc[(wrong-syntax [stx syntax?] [format-string string?] [v any/c] ...)
         any]{

Raises a syntax error using the result of
@racket[(current-syntax-context)] as the ``major'' syntax object and
the provided @racket[stx] as the specific syntax object. (The latter,
@racket[stx], is usually the one highlighted by DrRacket.) The error
message is constructed using the format string and arguments, and it
is prefixed with the special form name as described under
@racket[current-syntax-context].

@examples[#:eval the-eval
(eval:error (wrong-syntax #'here "expected ~s" 'there))
(eval:error
 (parameterize ([current-syntax-context #'(look over here)])
   (wrong-syntax #'here "expected ~s" 'there)))
]

A macro using @racket[wrong-syntax] might set the syntax context at the very
beginning of its transformation as follows:
@RACKETBLOCK[
(define-syntax (my-macro stx)
  (parameterize ([current-syntax-context stx])
    (syntax-case stx ()
      ___)))
]
Then any calls to @racket[wrong-syntax] during the macro's
transformation will refer to @racket[my-macro] (more precisely, the name that
referred to @racket[my-macro] where the macro was used, which may be
different due to renaming, prefixing, etc).
}


@;{----}

@section{Recording disappeared uses}

@defparam[current-recorded-disappeared-uses ids
          (or/c (listof identifier?) #f)]{

Parameter for tracking disappeared uses. Tracking is ``enabled'' when
the parameter has a non-false value. This is done automatically by
forms like @racket[with-disappeared-uses].
}

@defform[(with-disappeared-uses body-expr ... stx-expr)
         #:contracts ([stx-expr syntax?])]{

Evaluates the @racket[body-expr]s and @racket[stx-expr], catching identifiers
looked up using @racket[syntax-local-value/record]. Adds the caught identifiers
to the @racket['disappeared-use] syntax property of the syntax object produced
by @racket[stx-expr].

@history[#:changed "6.5.0.7" @elem{Added the option to include @racket[body-expr]s.}]
}

@defproc[(syntax-local-value/record [id identifier?] [predicate (-> any/c boolean?)])
         any/c]{

Looks up @racket[id] in the syntactic environment (as
@racket[syntax-local-value]). If the lookup succeeds and returns a
value satisfying the predicate, the value is returned and @racket[id]
is recorded as a disappeared use by calling @racket[record-disappeared-uses]. 
If the lookup fails or if the value
does not satisfy the predicate, @racket[#f] is returned and the
identifier is not recorded as a disappeared use.
}

@defproc[(record-disappeared-uses [id (or/c identifier? (listof identifier?))]
                                  [intro? boolean? (syntax-transforming?)])
         void?]{

Add @racket[id] to @racket[(current-recorded-disappeared-uses)]. If
@racket[id] is a list, perform the same operation on all the
identifiers. If @racket[intro?] is true, then
@racket[syntax-local-introduce] is first called on the identifiers.

If not used within the extent of a @racket[with-disappeared-uses] 
form or similar, has no effect.

@history[#:changed "6.5.0.7"
         @elem{Added the option to pass a single identifier instead of
               requiring a list.}
         #:changed "7.2.0.11"
         @elem{Added the @racket[intro?] argument.}]
}


@;{----}

@section{Miscellaneous utilities}

@defproc[(generate-temporary [name-base any/c 'g]) identifier?]{

Generates one fresh identifier. Singular form of
@racket[generate-temporaries]. If @racket[name-base] is supplied, it
is used as the basis for the identifier's name.
}

@defproc[(internal-definition-context-apply [intdef-ctx internal-definition-context?]
                                            [stx syntax?])
         syntax?]{

Equivalent to @racket[(internal-definition-context-introduce intdef-ctx stx 'add)]. The
@racket[internal-definition-context-apply] function is provided for backwards compatibility; the
 @racket[internal-definition-context-add-scopes] function is preferred.
}

@defproc[(syntax-local-eval [stx any/c]
                            [intdef-ctx (or/c internal-definition-context?
                                              #f
                                              (listof internal-definition-context?))
                             '()])
         any]{

Evaluates @racket[stx] as an expression in the current @tech{transformer environment} (that is, at
@tech{phase level} 1). If @racket[intdef-ctx] is not @racket[#f], the value provided for
@racket[intdef-ctx] is used to enrich @racket[stx]’s @tech{lexical information} and extend the
@tech{local binding context} in the same way as the fourth argument to @racket[local-expand].

@examples[#:eval the-eval
(define-syntax (show-me stx)
  (syntax-case stx ()
    [(show-me expr)
     (begin
       (printf "at compile time produces ~s\n"
               (syntax-local-eval #'expr))
       #'(printf "at run time produces ~s\n"
                 expr))]))
(show-me (+ 2 5))
(define-for-syntax fruit 'apple)
(define fruit 'pear)
(show-me fruit)
]

@history[
 #:changed "6.90.0.27" @elem{Changed @racket[intdef-ctx] to accept a list of internal-definition
                             contexts in addition to a single internal-definition context or
                             @racket[#f].}]
}

@defform[(with-syntax* ([pattern stx-expr] ...)
           body ...+)
         #:contracts ([stx-expr syntax?])]{

Similar to @racket[with-syntax], but the pattern variables of each
@racket[pattern] are bound in the @racket[stx-expr]s of subsequent
clauses as well as the @racket[body]s, and the @racket[pattern]s need
not bind distinct pattern variables; later bindings shadow earlier
bindings.

@examples[#:eval the-eval
(with-syntax* ([(x y) (list #'val1 #'val2)]
               [nest #'((x) (y))])
  #'nest)
]
}

@close-eval[the-eval]
