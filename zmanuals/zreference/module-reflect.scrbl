#lang zcribble/doc
@(require "mz.rkt"
          (for-label compiler/embed
                     syntax/modresolve
                     racket/phase+space))

@title{Module Names and Loading}

@(define mod-eval (make-base-eval))

@;------------------------------------------------------------------------
@section[#:tag "modnameresolver"]{Resolving Module Names}

@margin-note{The @racketmodname[syntax/modresolve] library provides additional
operations for resolving and manipulating module names.}

The name of a declared module is represented by a @deftech{resolved
module path}, which encapsulates either a symbol or a complete
filesystem path (see @secref["pathutils"]). A symbol normally refers
to a predefined module or module declared through reflective
evaluation (e.g., @racket[eval]). A filesystem path normally refers to
a module declaration that was loaded on demand via @racket[require] or
other forms.

A @deftech{module path} is a datum that matches the grammar for
@racket[_module-path] for @racket[require]. A module path is relative
to another module.

@defproc[(resolved-module-path? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{resolved module path},
@racket[#f] otherwise.}

@defproc[(make-resolved-module-path [path (or/c symbol? 
                                                (and/c path? complete-path?)
                                                (cons/c (or/c symbol?
                                                              (and/c path? complete-path?))
                                                        (non-empty-listof symbol?)))])
         resolved-module-path?]{

Returns a @tech{resolved module path} that encapsulates @racket[path],
where a list @racket[path] corresponds to a @tech{submodule} path.
If @racket[path] is a path or starts with a path, the path normally should be
@tech{cleanse}d (see @racket[cleanse-path]) and simplified (see
@racket[simplify-path], including consulting the file system).

A @tech{resolved module path} is interned. That is, if two
@tech{resolved module path} values encapsulate paths that are
@racket[equal?], then the @tech{resolved module path} values are
@racket[eq?].}

@defproc[(resolved-module-path-name [module-path resolved-module-path?])
         (or/c symbol? 
               (and/c path? complete-path?)
               (cons/c (or/c symbol?
                             (and/c path? complete-path?))
                       (non-empty-listof symbol?)))]{

Returns the path or symbol encapsulated by a @tech{resolved module path}.
A list result corresponds to a @tech{submodule} path.}


@defproc[(module-path? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] corresponds to a datum that matches
the grammar for @racket[_module-path] for @racket[require],
@racket[#f] otherwise. Note that a path (in the sense of
@racket[path?]) is a module path.}


@defparam[current-module-name-resolver proc
           (case->
            (resolved-module-path? (or/c #f namespace?) . -> . any)
            (module-path?
             (or/c #f resolved-module-path?)
             (or/c #f syntax?)
             boolean?
             . -> .
             resolved-module-path?))]{

A @tech{parameter} that determines the current @deftech{module name
resolver}, which manages the conversion from other kinds of module
references to a @tech{resolved module path}. For example,
when the expander encounters @racket[(require _module-path)] where
@racket[_module-path] is not an identifier, then the expander passes
@racket['@#,racket[_module-path]] to the module name resolver to obtain a symbol
or resolved module path. When such a @racket[require] appears within a
module, the @deftech{module path resolver} is also given the name of
the enclosing module, so that a relative reference can be converted to
an absolute symbol or @tech{resolved module path}. 

The default @tech{module name resolver} uses
@racket[collection-file-path] to convert @racket[lib] and
symbolic-shorthand module paths to filesystem paths. The 
@racket[collection-file-path] function, in turn, uses the
@racket[current-library-collection-links]
and @racket[current-library-collection-paths] parameters.

A @tech{module name resolver} takes two and four arguments:
@itemize[

  @item{When given two arguments, the first is a name for a module that
  is now declared in the current namespace, and the second is optionally
  a namespace from which the declaration was copied.
  The module name resolver's result in this case is ignored.

  The current module name resolver is called with two arguments by
  @racket[namespace-attach-module] or
  @racket[namespace-attach-module-declaration] to notify the resolver
  that a module declaration was attached to the current namespace (and
  should not be loaded in the future for the namespace's @tech{module registry}).
  Evaluation of a module declaration also calls the current module
  name resolver with two arguments, where the first is the declared
  module and the second is @racket[#f]. No other Racket operation
  invokes the module name resolver with two arguments, but other tools
  (such as DrRacket) might call this resolver in this mode to avoid
  redundant module loads.}
 
  @item{When given four arguments, the first is a module path,
  equivalent to a quoted @racket[_module-path] for @racket[require].
  The second is name for the source module, if
  any, to which the path is relative; if the second argument is
  @racket[#f], the module path is relative to @racket[(or
  (current-load-relative-directory) (current-directory))].  The third
  argument is a @tech{syntax object} that can be used for error
  reporting, if it is not @racket[#f]. If the last argument is
  @racket[#t], then the module declaration should be loaded (if it is
  not already), otherwise the module path should be simply resolved to
  a name. The result is the resolved name.}

]

For the second case, the standard module name resolver keeps a
table per @tech{module registry} containing loaded module name. If a resolved module path is
not in the table, and @racket[#f] is not provided as the fourth
argument to the @tech{module name resolver}, then the name is put into
the table and the corresponding file is loaded with a variant of
@racket[load/use-compiled] that passes the expected module name to the
@tech{compiled-load handler}.

While loading a file, the default @tech{module name resolver} sets the
@racket[current-module-declare-name] parameter to the resolved module
name (while the @tech{compiled-load handler} sets
@racket[current-module-declare-source]). Also, the default
@tech{module name resolver} records in a private @tech{continuation
mark} the module being loaded, and it checks whether such a mark
already exists; if such a continuation mark does exist in the current
continuation, then the @exnraise[exn:fail] with a message about a
dependency cycle.

The default module name resolver cooperates with the default
@tech{compiled-load handler}: on a module-attach notification,
bytecode-file information recorded by the @tech{compiled-load handler}
for the source namespace's @tech{module registry} is transferred to
the target namespace's @tech{module registry}.

The default module name resolver also maintains a small,
@tech{module registry}-specific cache that maps @racket[lib] and symbolic
module paths to their resolutions. This cache is consulted before
checking parameters such as @racket[current-library-collection-links]
and @racket[current-library-collection-paths], so results may
``stick'' even if those parameter values change. An entry is added to
the cache only when the fourth argument to the module name resolver is
true (indicating that a module should be loaded) and only when loading
succeeds.

Finally, the default module name resolver potentially treats a
@racket[submod] path specially. If the module path as the first
element of the @racket[submod] form refers to non-existent collection,
then instead of raising an exception, the default module name resolver
synthesizes an uninterned symbol module name for the resulting
@tech{resolved module path}. This special treatment of submodule paths
is consistent with the special treatment of nonexistent submodules by
the @tech{compiled-load handler}, so that @racket[module-declared?]
can be used more readily to check for the existence of a submodule.

Module loading is suppressed (i.e., @racket[#f] is supplied as a fourth
argument to the module name resolver) when resolving module paths in
@tech{syntax objects} (see @secref["stxobj-model"]). When a
@tech{syntax object} is manipulated, the current namespace might not
match the original namespace for the syntax object, and the module
should not necessarily be loaded in the current namespace.

For historical reasons, the default module name resolver currently
accepts three arguments, in addition to two and four. Three arguments
are treated the same as four arguments with the fourth argument as
@racket[#t], except that an error is also logged. Support for three
arguments will be removed in a future version.

The @racket[current-module-name-resolver] binding is provided as
@tech{protected} in the sense of @racket[protect-out].

@history[#:changed "6.0.1.12" 
         @elem{Added error logging to the default module name resolver
               when called with three arguments.}
         #:changed "7.0.0.17"
         @elem{Added special treatment of @racket[submod] forms with a
               nonexistent collection by the default module name
               resolver.}
         #:changed "8.2.0.4" @elem{Changed binding to @tech{protected}.}]}


@defparam[current-module-declare-name name (or/c resolved-module-path? #f)]{

A @tech{parameter} that determines a module name that is used when evaluating
a @racket[module] declaration (when the parameter value is not
@racket[#f]). In that case, the @racket[_id] from the @racket[module]
declaration is ignored, and the parameter's value is used as the name
of the declared module.

When declaring @tech{submodules}, @racket[current-module-declare-name]
determines the name used for the submodule's root module, while its
submodule path relative to the root module is unaffected.}


@defparam[current-module-declare-source src (or/c symbol? (and/c path? complete-path?) #f)]{

A @tech{parameter} that determines source information to be associated with a
module when evaluating a @racket[module] declaration. Source
information is used in error messages and reflected by
@racket[variable-reference->module-source]. When the parameter value
is @racket[#f], the module's name (as determined by
@racket[current-module-declare-name]) is used as the source name
instead of the parameter value.}


@defparam[current-module-path-for-load path (or/c #f module-path? 
                                                  (and/c syntax? 
                                                         (lambda (stx)
                                                           (module-path? (syntax->datum s)))))]{

A @tech{parameter} that determines a module path used for
@racket[exn:fail:syntax:missing-module] and
@racket[exn:fail:filesystem:missing-module] exceptions as raised by the
default @tech{load handler}.  The parameter is normally set by a
@tech{module name resolver}.}

@;------------------------------------------------------------------------
@section[#:tag "modpathidx"]{Compiled Modules and References}

While expanding a @racket[module] declaration, the expander resolves
module paths for imports to load module declarations as necessary and
to determine imported bindings, but the compiled form of a
@racket[module] declaration preserves the original module path.
Consequently, a compiled module can be moved to another filesystem,
where the module name resolver can resolve inter-module references
among compiled code.

When a module reference is extracted from compiled form (see
@racket[module-compiled-imports]) or from syntax objects in macro
expansion (see @secref["stxops"]), the module reference is reported in
the form of a @deftech{module path index}. A @tech{module path index}
is a semi-interned (multiple references to the same relative module
tend to use the same @tech{module path index} value, but not always)
opaque value that encodes a module path (see @racket[module-path?])
and either a @tech{resolved module path} or another @tech{module path
index} to which it is relative.

A @tech{module path index} that uses both @racket[#f] for its path and
base @tech{module path index} represents ``self''---i.e., the module
declaration that was the source of the @tech{module path index}---and
such a @tech{module path index} can be used as the root for a chain of
@tech{module path index}es at compile time. For example, when
extracting information about an identifier's binding within a module,
if the identifier is bound by a definition within the same module, the
identifier's source module is reported using the ``self'' @tech{module
path index}. If the identifier is instead defined in a module that is
imported via a module path (as opposed to a literal module name), then
the identifier's source module will be reported using a @tech{module
path index} that contains the @racket[require]d module path and the
``self'' @tech{module path index}. A ``self'' @tech{module path index}
has a submodule path when the module that it refers to is a
@tech{submodule}.

A @tech{module path index} has state. When it is @deftech{resolved} to
a @tech{resolved module path}, then the @tech{resolved module path} is
stored with the @tech{module path index}. In particular, when a module
is loaded, its root @tech{module path index} is resolved to match the
module's declaration-time name. This resolved path is forgotten,
however, in identifiers that the module contributes to the compiled
and marshaled form of other modules. The transient nature of resolved
names allows the module code to be loaded with a different resolved
name than the name when it was compiled.

Two @tech{module path index} values are @racket[equal?] when they have
@racket[equal?] path and base values (even if they have different
@tech{resolved} values).

@defproc[(module-path-index? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{module path index},
@racket[#f] otherwise.}


@defproc[(module-path-index-resolve [mpi module-path-index?]
                                    [load? any/c #f]
                                    [src-stx (or/c syntax? #f) #f])
         resolved-module-path?]{

Returns a @tech{resolved module path} for the resolved module name,
computing the resolved name (and storing it in @racket[mpi]) if it has
not been computed before.

Resolving a @tech{module path index} uses the current @tech{module
name resolver} (see @racket[current-module-name-resolver]). Depending
on the kind of module paths encapsulated by @racket[mpi], the computed
resolved name can depend on the value of
@racket[current-load-relative-directory] or
@racket[current-directory]. The @racket[load?] argument is propagated as
the last argument to the @tech{module name resolver}, while the
@racket[src-stx] argument is propagated as the next-to-last argument.

Beware that concurrent resolution in namespaces that share a module
registry can create race conditions when loading modules. See also
@racket[namespace-call-with-registry-lock].

If @racket[mpi] represents a ``self'' (see above) module path that was
not created by the expander as already resolved, then
@racket[module-path-index-resolve] raises @racket[exn:fail:contract]
without calling the module name resolver.

See also @racket[resolve-module-path-index].

@history[#:changed "6.90.0.16" @elem{Added the @racket[load?] optional argument.}
         #:changed "8.2" @elem{Added the @racket[src-stx] optional argument.}]}


@defproc[(module-path-index-split [mpi module-path-index?])
         (values (or/c module-path? #f)
                 (or/c module-path-index? resolved-module-path? #f))]{

Returns two values: a module path, and a base path---either a
@tech{module path index}, @tech{resolved module path}, or
@racket[#f]---to which the first path is relative.

A @racket[#f] second result means that the path is relative to an
unspecified directory (i.e., its resolution depends on the value of
@racket[current-load-relative-directory] and/or
@racket[current-directory]).

A @racket[#f] for the first result implies a @racket[#f] for the
second result, and means that @racket[mpi] represents ``self'' (see
above). Such a @tech{module path index} may have a non-@racket[#f]
submodule path as reported by @racket[module-path-index-submodule].}


@defproc[(module-path-index-submodule [mpi module-path-index?])
         (or/c #f (non-empty-listof symbol?))]{

Returns a non-empty list of symbols if @racket[mpi] is a ``self'' (see
above) @tech{module path index} that refers to a @tech{submodule}. The
result is always @racket[#f] if either result of
@racket[(module-path-index-split mpi)] is non-@racket[#f].}


@defproc[(module-path-index-join [path (or/c module-path? #f)]
                                 [base (or/c module-path-index? resolved-module-path? #f)]
                                 [submod (or/c #f (non-empty-listof symbol?)) #f])
         module-path-index?]{

Combines @racket[path], @racket[base], and @racket[submod] to create a
new @tech{module path index}. The @racket[path] argument can be
@racket[#f] only if @racket[base] is also @racket[#f]. The
@racket[submod] argument can be a list only when @racket[path] and
@racket[base] are both @racket[#f].}

@defproc[(compiled-module-expression? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a compiled @racket[module]
declaration, @racket[#f] otherwise. See also
@racket[current-compile].}


@defproc*[([(module-compiled-name [compiled-module-code compiled-module-expression?])
            (or/c symbol? (cons/c symbol? (non-empty-listof symbol?)))]
           [(module-compiled-name [compiled-module-code compiled-module-expression?]
                                  [name (or/c symbol? (cons/c symbol? (non-empty-listof symbol?)))])
            compiled-module-expression?])]{

Takes a module declaration in compiled form and either gets the
module's declared name (when @racket[name] is not provided) or returns
a revised module declaration with the given @racket[name].

The name is a symbol for a top-level module, or a symbol paired with a list of symbols
where the list reflects the @tech{submodule} path to
the module starting with the top-level module's declared name.}


@defproc*[([(module-compiled-submodules [compiled-module-code compiled-module-expression?]
                                        [non-star? any/c])
            (listof compiled-module-expression?)]
           [(module-compiled-submodules [compiled-module-code compiled-module-expression?]
                                        [non-star? any/c]
                                        [submodules (listof compiled-module-expression?)])
            compiled-module-expression?])]{

Takes a module declaration in compiled form and either gets the
module's @tech{submodules} (when @racket[submodules] is not provided) or
returns a revised module declaration with the given
@racket[submodules]. The @racket[non-star?] argument determines
whether the result or new submodule list corresponds to
@racket[module] declarations (when @racket[non-star?] is true)
or @racket[module*] declarations (when @racket[non-star?] is @racket[#f]).}


@defproc[(module-compiled-imports [compiled-module-code compiled-module-expression?])
         (listof (cons/c (or/c exact-integer? #f) 
                         (listof module-path-index?)))]{

Takes a module declaration in compiled form and returns an association
list mapping @tech{phase level} shifts (where @racket[#f] corresponds
to a shift into the @tech{label phase level}) to module references for
the module's explicit imports.}


@defproc[(module-compiled-exports [compiled-module-code compiled-module-expression?]
                                  [verbosity (or/c #f 'defined-names) #f])
         (values (listof (cons/c phase+space? list?))
                 (listof (cons/c phase+space? list?)))]{

Returns two association lists mapping from a combination of @tech{phase level}
and @tech{binding space} to exports at
the corresponding phase and space. The first association list is for exported
variables, and the second is for exported syntax. Beware however, that
value bindings re-exported though a @tech{rename transformer} are in
the syntax list instead of the value list. See @racket[phase+space?]
for information on the phase-and-space representation.

Each associated list, which is represented by @racket[list?] in the
result contracts above, more precisely matches the contract

@racketblock[
(listof (list/c symbol?
                (listof 
                 (or/c module-path-index?
                       (list/c module-path-index?
                               phase+space?
                               symbol?
                               phase+space?)))
                (code:comment @#,elem{only if @racket[verbosity] is @racket['defined-names]:})
                symbol?))
]

For each element of the list, the leading symbol is the name of the
export.

The second part---the list of @tech{module path index} values,
etc.---describes the origin of the exported identifier. If the origin
list is @racket[null], then the exported identifier is defined in the
module. If the exported identifier is re-exported, instead, then the
origin list provides information on the import that was re-exported.
The origin list has more than one element if the binding was imported
multiple times from (possibly) different sources.

The last part, a symbol, is included only if @racket[verbosity] is
@racket['defined-names]. In that case, the included symbol is the name
of the definition within its defining module (which may be different
than the name that is exported).

For each origin, a @tech{module path index} by itself means that the
binding was imported with a @tech{phase level} shift of @racket[0]
(i.e., a plain @racket[require] without @racket[for-meta],
@racket[for-syntax], etc.) into the default @tech{binding space} (i.e.,
without @racket[for-space]), and the imported identifier has the same name
as the re-exported name. An origin represented with a list indicates
explicitly the import, the @tech{phase level} plus @tech{binding space}
where the imported identifier is bound (see @racket[phase+space?] for more
information on the representation), the symbolic name of the import
as bound in the importing module, and the @tech{phase level} plus
@tech{binding space} of the identifier from the exporting module.

@examples[#:eval mod-eval
          (module-compiled-exports
           (compile
            '(module banana racket/base
               (require (only-in racket/math pi)
                        (for-syntax racket/base))
               (provide pi
                        (rename-out [peel wrapper])
                        bush
                        cond
                        (for-syntax compile-time))
               (define peel pi)
               (define bush (* 2 pi))
               (begin-for-syntax
                 (define compile-time (current-seconds)))))
           'defined-names)]

@history[#:changed "7.5.0.6" @elem{Added the @racket[verbosity] argument.}
         #:changed "8.2.0.3" @elem{Generalized results to phase--space combinations.}]}



@defproc[(module-compiled-indirect-exports [compiled-module-code compiled-module-expression?])
         (listof (cons/c exact-integer? (listof symbol?)))]{

Returns an association list mapping @tech{phase level} values to
symbols that represent variables within the module. These definitions
are not directly accessible from source, but they are accessible from
bytecode, and the order of the symbols in each list corresponds to an
order for bytecode access.

@history[#:added "6.5.0.5"]}


@defproc[(module-compiled-language-info [compiled-module-code compiled-module-expression?])
         (or/c #f (vector/c module-path? symbol? any/c))]{

@guidealso["module-runtime-config"]

Returns information intended to reflect the ``language'' of the
module's implementation as originally attached to the syntax of the
module's declaration though the @indexed-racket['module-language]
@tech{syntax property}. See also @racket[module].

If no information is available for the module, the result is
@racket[#f]. Otherwise, the result is @racket[(vector _mp _name _val)]
such that @racket[((dynamic-require _mp _name) _val)] should return
function that takes two arguments. The function's arguments are a key
for reflected information and a default value.  Acceptable keys and
the interpretation of results is up to external tools, such as
DrRacket.  If no information is available for a given key, the result
should be the given default value.

See also @racket[module->language-info] and
@racketmodname[racket/language-info].}

@defproc[(module-compiled-cross-phase-persistent?
          [compiled-module-code compiled-module-expression?])
         boolean?]{

Returns @racket[#t] if @racket[compiled-module-code] represents a
@tech{cross-phase persistent} module, @racket[#f] otherwise.}


@defproc[(module-compiled-realm [compiled-module-code compiled-module-expression?])
         symbol?]{

Returns the @tech{realm} of the module represented by
@racket[compiled-module-code].

@history[#:added "8.4.0.2"]}

@;------------------------------------------------------------------------
@section[#:tag "dynreq"]{Dynamic Module Access}

@defproc[(dynamic-require [mod (or/c module-path?
                                     resolved-module-path?
                                     module-path-index?)]
                          [provided (or/c symbol? #f 0 void?)]
                          [fail-thunk (or/c 'error (-> any)) 'error]
                          [syntax-thunk (or/c 'eval (-> any)) 'eval])
         (or/c void? any/c)]{

@margin-note{Because @racket[dynamic-require] is a procedure, giving a plain S-expression for
@racket[mod] the same way as you would for a @racket[require] expression likely won't give you
expected results. What you need instead is something that evaluates to an S-expression; using
@racket[quote] is one way to do it.}

Dynamically @tech{instantiates} the module specified by @racket[mod]
in the current namespace's registry at the namespace's @tech{base
phase}, if it is not yet @tech{instantiate}d. The current @tech{module
name resolver} may load a module declaration to resolve @racket[mod]
(see @racket[current-module-name-resolver]); the path is resolved
relative to @racket[current-load-relative-directory] and/or
@racket[current-directory]. Beware that concurrent @racket[dynamic-require]s
in namespaces that share a @tech{module registry} can create race
conditions; see also @racket[namespace-call-with-registry-lock].

If @racket[provided] is @racket[#f], then the result is @|void-const|,
and the module is not @tech{visit}ed (see @secref["mod-parse"]) or
even made @tech{available} (for on-demand @tech{visits}) in phases
above the @tech{base phase}.

@examples[#:eval mod-eval
  (module a racket/base (displayln "hello"))
  (dynamic-require ''a #f)
]

@margin-note{The double quoted @racket[''a] evaluates to the @racket[_root-module-path] @racket['a]
(see the grammar for @racket[require]). Using @racket['a] for @racket[mod] won't work,
because that evaluates to @racket[_root-module-path] @racket[a], and the example is
not a module installed in a collection. Using @racket[a] won't work, because @racket[a]
is an undefined variable.

Declaring @racket[(module a ....)] within another module, instead of in
the @racket[read-eval-print] loop, would create a submodule. In that case,
@racket[(dynamic-require ''a #f)] would not access the module, because @racket[''a]
does not refer to a submodule.}

When @racket[provided] is a symbol, the value of the module's export
with the given name is returned, and still the module is not
@tech{visit}ed or made @tech{available} in higher phases.

@examples[#:eval mod-eval
  (module b racket/base
    (provide dessert)
    (define dessert "gulab jamun"))
  (dynamic-require ''b 'dessert)
]

If the module exports @racket[provided] as syntax, then @racket[syntax-thunk]
is called if it is a procedure, and its result is the result of the
@racket[dynamic-require] call. If @racket[syntax-thunk] is @racket['eval], a use of the binding
is expanded and evaluated in a fresh namespace to which the module is
attached, which means that the module is @tech{visit}ed in the fresh
namespace. The expanded syntax must return a single value.

@examples[#:eval mod-eval
  (module c racket/base
    (require (for-syntax racket/base))
    (provide dessert2)
    (define dessert "nanaimo bar")
    (define-syntax dessert2
      (make-rename-transformer #'dessert)))
  (dynamic-require ''c 'dessert2)
]

If the module has no such exported variable or syntax, then
@racket[fail-thunk] is called, or the
@exnraise[exn:fail:contract] if @racket[fail-thunk] is @racket['error].
If the variable named by @racket[provided]
is exported protected (see @secref["modprotect"]), then the
@exnraise[exn:fail:contract].

If @racket[provided] is @racket[0], then the module is
@tech{instantiate}d but not @tech{visit}ed, the same as when
@racket[provided] is @racket[#f]. With @racket[0], however, the module
is made @tech{available} in higher phases.

If @racket[provided] is @|void-const|, then the module is
@tech{visit}ed but not @tech{instantiate}d (see @secref["mod-parse"]),
and the result is @|void-const|.

More examples using different @racket[module-path] grammar expressions are given below:

@examples[#:eval mod-eval
  (dynamic-require 'racket/base #f)
]

@examples[#:eval mod-eval
  (dynamic-require (list 'lib "racket/base") #f)
]

@examples[#:eval mod-eval
  (module a racket/base
    (module b racket/base
      (provide inner-dessert)
      (define inner-dessert "tiramisu")))
  (dynamic-require '(submod 'a b) 'inner-dessert)
]

The last line in the above example could instead have been written as

@examples[#:eval mod-eval
  (dynamic-require ((lambda () (list 'submod ''a 'b))) 'inner-dessert)
]

which is equivalent.

@history[#:changed "8.16.0.3" @elem{Added the @racket[syntax-thunk] argument and
                                    changed to allow @racket['error] for @racket[fail-thunk].}]}


@defproc[(dynamic-require-for-syntax [mod module-path?]
                                     [provided (or/c symbol? #f)]
                                     [fail-thunk (or/c 'error (-> any)) 'error]
                                     [syntax-thunk (or/c 'eval (-> any)) 'eval])
         any]{

Like @racket[dynamic-require], but in a @tech{phase} that is @math{1}
more than the namespace's @tech{base phase}.

@history[#:changed "8.16.0.3" @elem{Added the @racket[syntax-thunk] argument and
                                    changed to allow @racket['error] for @racket[fail-thunk].}]}


@defproc[(module-declared?
          [mod (or/c module-path? module-path-index? 
                     resolved-module-path?)]
          [load? any/c #f])
         boolean?]{

Returns @racket[#t] if the module indicated by @racket[mod] is
@tech{declare}d (but not necessarily @tech{instantiate}d or @tech{visit}ed)
in the current namespace, @racket[#f] otherwise.

If @racket[load?] is @racket[#t] and @racket[mod] is not a
@tech{resolved module path}, the module is loaded in the process of
resolving @racket[mod] (as for @racket[dynamic-require] and other
functions). Checking for the declaration of a @tech{submodule} does
not trigger an exception if the submodule cannot be loaded because
it does not exist, either within a root module that does exist or
because the root module does not exist.}


@defproc[(module->language-info
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)]
          [load? any/c #f])
         (or/c #f (vector/c module-path? symbol? any/c))]{

Returns information intended to reflect the ``language'' of the
implementation of @racket[mod]. If @racket[mod] is a 
@tech{resolved module path} or @racket[load?] is @racket[#f], the
module named by @racket[mod] must be @tech{declare}d (but not necessarily
@tech{instantiate}d or @tech{visit}ed) in the current namespace;
otherwise, @racket[mod] may be loaded (as for @racket[dynamic-require]
and other functions). The information returned by
@racket[module->language-info] is the same as would have been returned
by @racket[module-compiled-language-info] applied to the module's
implementation as compiled code.

A module can be @tech{declare}d by using @racket[dynamic-require].

@examples[#:eval mod-eval
          (dynamic-require 'racket/dict (void))
          (module->language-info 'racket/dict)]}

@defproc[(module->imports
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)])
         (listof (cons/c (or/c exact-integer? #f) 
                         (listof module-path-index?)))]{

 Like @racket[module-compiled-imports], but produces the
 imports of @racket[mod], which must be @tech{declare}d (but
 not necessarily @tech{instantiate}d or @tech{visit}ed) in
 the current namespace. See @racket[module->language-info] for
 an example of declaring an existing module.
 
@examples[#:eval mod-eval
          (module banana racket/base
            (require (only-in racket/math pi))
            (provide peel)
            (define peel pi)
            (define bush (* 2 pi)))
          (module->imports ''banana)]}


@defproc[(module->exports
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)]
          [verbosity (or/c #f 'defined-names) #f])
         (values (listof (cons/c phase+space? list?))
                 (listof (cons/c phase+space? list?)))]{

 Like @racket[module-compiled-exports], but produces the
 exports of @racket[mod], which must be @tech{declare}d (but
 not necessarily @tech{instantiate}d or @tech{visit}ed) in
 the current namespace. See @racket[module->language-info] for
 an example of declaring an existing module.
 
@examples[#:eval mod-eval
          (module banana racket/base
            (require (only-in racket/math pi))
            (provide (rename-out [peel wrapper]))
            (define peel pi)
            (define bush (* 2 pi)))
          (module->exports ''banana)]

@history[#:changed "7.5.0.6" @elem{Added the @racket[verbosity] argument.}
         #:changed "8.2.0.3" @elem{Generalized results to phase--space combinations.}]}


@defproc[(module->indirect-exports
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)])
         (listof (cons/c exact-integer? (listof symbol?)))]{

 Like @racket[module-compiled-indirect-exports], but produces the
 indirect exports of @racket[mod], which must be
 @tech{declare}d (but not necessarily @tech{instantiate}d or
 @tech{visit}ed) in the current namespace. See
 @racket[module->language-info] for an example of declaring
 an existing module.

@examples[#:eval mod-eval
          (module banana racket/base
            (require (only-in racket/math pi))
            (provide peel)
            (define peel pi)
            (define bush (* 2 pi)))
          (module->indirect-exports ''banana)]

@history[#:added "6.5.0.5"]}


@defproc[(module->realm 
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)])
         symbol?]{

 Like @racket[module-compiled-realm], but produces the
 @tech{realm} of @racket[mod], which must be @tech{declare}d
 (but not necessarily @tech{instantiate}d or @tech{visit}ed)
 in the current namespace.

@history[#:added "8.4.0.2"]}


@defproc[(module-predefined?
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)])
         boolean?]{

Reports whether @racket[mod] refers to a module that is predefined for
the running Racket instance. Predefined modules always have a symbolic
resolved module path, and they may be predefined always or
specifically within a particular executable (such as one created by
@exec{raco exe} or @racket[create-embedding-executable]).}

@(close-eval mod-eval)

@;------------------------------------------------------------------------
@section[#:tag "modcache"]{Module Cache}

The expander keeps a place-local module cache in order to save time
while loading modules that have been previously declared.

@defproc[(module-cache-clear!) void?]{
  Clears the place-local module cache.

  @history[#:added "8.4.0.5"]
}
