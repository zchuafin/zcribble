#lang zcribble/doc
@(require zcribble/manual "guide-utils.rkt"
          (for-label racket/flonum
                     racket/unsafe/ops
                     racket/performance-hint
                     ffi/unsafe))

@title[#:tag "performance"]{Performance}

@section-index["benchmarking"]
@section-index["speed"]

Alan Perlis famously quipped ``Lisp programmers know the value of
everything and the cost of nothing.'' A Racket programmer knows, for
example, that a @racket[lambda] anywhere in a program produces a value
that is closed over its lexical environment---but how much does
allocating that value cost? While most programmers have a reasonable
grasp of the cost of various operations and data structures at the
machine level, the gap between the Racket language model and the
underlying computing machinery can be quite large.

In this chapter, we narrow the gap by explaining details of the
Racket compiler and runtime system and how they affect the runtime
and memory performance of Racket code.

@; ----------------------------------------------------------------------

@section[#:tag "DrRacket-perf"]{Performance in DrRacket}

By default, DrRacket instruments programs for debugging, and
debugging instrumentation (provided by the
@other-doc['(lib "errortrace/scribblings/errortrace.scrbl")]
library) can significantly degrade performance for
some programs. Even when debugging is disabled through the
@onscreen{Choose Language...} dialog's @onscreen{Show Details} panel,
the @onscreen{Preserve stacktrace} checkbox is clicked by default,
which also affects performance. Disabling debugging and stacktrace
preservation provides performance results that are more consistent
with running in plain @exec{racket}.

Even so, DrRacket and programs developed within DrRacket use the same
Racket virtual machine, so garbage collection times (see
@secref["gc-perf"]) may be longer in DrRacket than when a program is
run by itself, and DrRacket threads may impede execution of program
threads. @bold{For the most reliable timing results for a program, run in
plain @exec{racket} instead of in the DrRacket development environment.}
Non-interactive mode should be used instead of the
@tech["REPL"] to benefit from the module system. See
@secref["modules-performance"] for details.

@; ----------------------------------------------------------------------

@section[#:tag "virtual-machines"]{Racket Virtual Machine Implementations}

Racket is available in two implementations, @deftech{CS} and
@deftech{BC}:

@itemlist[

 @item{@tech{CS} is the current default implementation. It is
       a newer implementation that builds on
       @hyperlink["https://www.scheme.com/"]{Chez Scheme} as its core
       virtual machine. This implementation performs better than
       the @tech{BC} implementation for most programs.

       For this implementation, @racket[(system-type 'vm)] reports
       @racket['chez-scheme] and @racket[(system-type 'gc)] reports
       @racket['cs].}

 @item{@tech{BC} is an older implementation, and was the default until version 8.0.
       The implementation features a compiler and runtime written in C,
       with a precise garbage collector and a just-in-time compiler (JIT)
       on most platforms.

       For this implementation, @racket[(system-type 'vm)] reports
       @racket['racket].

       The BC implementation itself has two variants, @deftech{3m} and
       @deftech{CGC}:

       @itemlist[

        @item{@tech{3m} is the normal BC variant with a precise
             garbage collector.

             For this variant, @racket[(system-type 'gc)] reports
            @racket['3m].}


        @item{@tech{CGC} is the oldest variant. It's the same basic
              implementation as @tech{3m} (i.e., the same virtual
              machine), but compiled to rely on a ``conservative''
              garbage collector, which affects the way that Racket
              interacts with C code. See @secref["CGC versus 3m"
              #:doc inside-doc] in @other-manual[inside-doc] for more
              information.

              For this variant, @racket[(system-type 'gc)] reports
              @racket['cgc].}

       ]}

]

In general, Racket programs should run the same in all variants.
Furthermore, the performance characteristics of Racket program should
be similar in the @tech{CS} and @tech{BC} implementations. The cases
where a program may depend on the implementation will typically
involve interactions with foreign libraries; in particular, the Racket
C API described in @other-doc[inside-doc] is different for the
@tech{CS} implementation versus the @tech{BC} implementation.

@; ----------------------------------------------------------------------

@section[#:tag "JIT"]{Bytecode, Machine Code, and Just-in-Time (JIT) Compilers}

Every definition or expression to be evaluated by Racket is compiled
to an internal bytecode format, although ``bytecode'' may actually be
native machine code. In interactive mode, this compilation occurs
automatically and on-the-fly. Tools like @exec{raco make} and
@exec{raco setup} marshal compiled bytecode to a file, so that you do
not have to compile from source every time that you run a program.
See @secref["compile"] for more information on generating
bytecode files.

The bytecode compiler applies all standard optimizations, such as
constant propagation, constant folding, inlining, and dead-code
elimination. For example, in an environment where @racket[+] has its
usual binding, the expression @racket[(let ([x 1] [y (lambda () 4)]) (+
1 (y)))] is compiled the same as the constant @racket[5].

For the @tech{CS} implementation of Racket, the main bytecode format
is non-portable machine code. For the @tech{BC} implementation of
Racket, bytecode is portable in the sense that it is
machine-independent. Setting @racket[current-compile-target-machine]
to @racket[#f] selects a separate machine-independent and
variant-independent format on all Racket implementations, but running
code in that format requires an additional internal conversion step to
the implementation's main bytecode format.

Machine-independent bytecode for the @tech{BC} implementation is further
compiled to native code via a @deftech{just-in-time} or @deftech{JIT}
compiler. The @tech{JIT} compiler substantially speeds programs that
execute tight loops, arithmetic on small integers, and arithmetic on
inexact real numbers. Currently, @tech{JIT} compilation is supported
for x86, x86_64 (a.k.a. AMD64), 32-bit ARM, and 32-bit PowerPC processors.
The @tech{JIT} compiler can be disabled via the
@racket[eval-jit-enabled] parameter or the @DFlag{no-jit}/@Flag{j}
command-line flag for @exec{racket}. Setting @racket[eval-jit-enabled]
to @racket[#f] has no effect on the @tech{CS} implementation of Racket.

The @tech{JIT} compiler works incrementally as functions are applied,
but the @tech{JIT} compiler makes only limited use of run-time
information when compiling procedures, since the code for a given
module body or @racket[lambda] abstraction is compiled only once. The
@tech{JIT}'s granularity of compilation is a single procedure body,
not counting the bodies of any lexically nested procedures. The
overhead for @tech{JIT} compilation is normally so small that it is
difficult to detect.

For information about viewing intermediate Racket code
representations, especially for the @tech{CS} implementation, see
@refsecref["compiler-inspect"].

@; ----------------------------------------------------------------------

@section[#:tag "modules-performance"]{Modules and Performance}

The module system aids optimization by helping to ensure that
identifiers have the usual bindings. That is, the @racket[+] provided
by @racketmodname[racket/base] can be recognized by the compiler and
inlined. In contrast, in a traditional interactive Scheme system, the top-level
@racket[+] binding might be redefined, so the compiler cannot assume a
fixed @racket[+] binding (unless special flags or declarations
are used to compensate for the lack of a module system).

Even in the top-level environment, importing with @racket[require]
enables some inlining optimizations. Although a @racket[+] definition
at the top level might shadow an imported @racket[+], the shadowing
definition applies only to expressions evaluated later.

Within a module, inlining and constant-propagation optimizations take
additional advantage of the fact that definitions within a module
cannot be mutated when no @racket[set!] is visible at compile
time. Such optimizations are unavailable in the top-level
environment. Although this optimization within modules is important
for performance, it hinders some forms of interactive development and
exploration. The @racket[compile-enforce-module-constants] parameter
disables the compiler's assumptions about module
definitions when interactive exploration is more important. See
@secref["module-set"] for more information.

The compiler may inline functions or propagate constants across module
boundaries. To avoid generating too much code in the case of function
inlining, the compiler is conservative when choosing candidates for
cross-module inlining; see @secref["func-call-performance"] for
information on providing inlining hints to the compiler.

The later section @secref["letrec-performance"] provides some
additional caveats concerning inlining of module bindings.

@; ----------------------------------------------------------------------

@section[#:tag "func-call-performance"]{Function-Call Optimizations}

When the compiler detects a function call to an immediately visible
function, it generates more efficient code than for a generic call,
especially for tail calls. For example, given the program

@racketblock[
(letrec ([odd (lambda (x) 
                (if (zero? x) 
                    #f 
                    (even (sub1 x))))] 
         [even (lambda (x) 
                 (if (zero? x) 
                     #t 
                     (odd (sub1 x))))]) 
  (odd 40000000))
]

the compiler can detect the @racket[odd]--@racket[even] loop and
produce code that runs much faster via loop unrolling and related
optimizations.

Within a module form, @racket[define]d variables are lexically scoped
like @racket[letrec] bindings, and definitions within a module
therefore permit call optimizations, so

@racketblock[
(define (odd x) ....)
(define (even x) ....)
]

within a module would perform the same as the @racket[letrec] version.

For direct calls to functions with keyword arguments, the compiler can
typically check keyword arguments statically and generate a direct
call to a non-keyword variant of the function, which reduces the
run-time overhead of keyword checking. This optimization applies only
for keyword-accepting procedures that are bound with @racket[define].

For immediate calls to functions that are small enough, the compiler
may inline the function call by replacing the call with the body of
the function. In addition to the size of the target function's body,
the compiler's heuristics take into account the amount of inlining
already performed at the call site and whether the called function
itself calls functions other than simple primitive operations. When a
module is compiled, some functions defined at the module level are
determined to be candidates for inlining into other modules; normally,
only trivial functions are considered candidates for cross-module
inlining, but a programmer can wrap a function definition with
@racket[begin-encourage-inline] to encourage inlining
of the function.

Primitive operations like @racket[pair?], @racket[car], and
@racket[cdr] are inlined at the machine-code level by the bytecode or @tech{JIT}
compiler. See also the later section @secref["fixnums+flonums"] for
information about inlined arithmetic operations.

@; ----------------------------------------------------------------------

@section{Mutation and Performance}

Using @racket[set!] to mutate a variable can lead to bad
performance. For example, the microbenchmark

@racketmod[
racket/base

(define (subtract-one x)
  (set! x (sub1 x))
  x)

(time
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (subtract-one n)))))
]

runs much more slowly than the equivalent

@racketmod[
racket/base

(define (subtract-one x)
  (sub1 x))

(time
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (subtract-one n)))))
]

In the first variant, a new location is allocated for @racket[x] on
every iteration, leading to poor performance. A more clever compiler
could unravel the use of @racket[set!] in the first example, but since
mutation is discouraged (see @secref["using-set!"]), the compiler's
effort is spent elsewhere.

More significantly, mutation can obscure bindings where inlining and
constant-propagation might otherwise apply. For example, in

@racketblock[
(let ([minus1 #f])
  (set! minus1 sub1)
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (minus1 n)))))
]

the @racket[set!] obscures the fact that @racket[minus1] is just
another name for the built-in @racket[sub1].

@; ----------------------------------------------------------------------

@section[#:tag "letrec-performance"]{@racket[letrec] Performance}

When @racket[letrec] is used to bind only procedures and literals,
then the compiler can treat the bindings in an optimal manner,
compiling uses of the bindings efficiently. When other kinds of
bindings are mixed with procedures, the compiler may be less able to
determine the control flow.

For example,

@racketblock[
(letrec ([loop (lambda (x) 
                (if (zero? x) 
                    'done
                    (loop (next x))))] 
         [junk (display loop)]
         [next (lambda (x) (sub1 x))])
  (loop 40000000))
]

likely compiles to less efficient code than

@racketblock[
(letrec ([loop (lambda (x) 
                (if (zero? x) 
                    'done
                    (loop (next x))))] 
         [next (lambda (x) (sub1 x))])
  (loop 40000000))
]

In the first case, the compiler likely does not know that
@racket[display] does not call @racket[loop]. If it did, then
@racket[loop] might refer to @racket[next] before the binding is
available.

This caveat about @racket[letrec] also applies to definitions of
functions and constants as internal definitions or in modules. A
definition sequence in a module body is analogous to a sequence of
@racket[letrec] bindings, and non-constant expressions in a module
body can interfere with the optimization of references to later
bindings.

@; ----------------------------------------------------------------------

@section[#:tag "fixnums+flonums"]{Fixnum and Flonum Optimizations}

A @deftech{fixnum} is a small exact integer. In this case, ``small''
depends on the platform. For a 32-bit machine, numbers that can be
expressed in 29-30 bits plus a sign bit are represented as fixnums. On
a 64-bit machine, 60-62 bits plus a sign bit are available.

A @deftech{flonum} is used to represent any inexact real number. They
correspond to 64-bit IEEE floating-point numbers on all platforms.

Inlined fixnum and flonum arithmetic operations are among the most
important advantages of the compiler. For example, when
@racket[+] is applied to two arguments, the generated machine code
tests whether the two arguments are fixnums, and if so, it uses the
machine's instruction to add the numbers (and check for overflow). If
the two numbers are not fixnums, then it checks whether
both are flonums; in that case, the machine's floating-point
operations are used directly. For functions that take any number of
arguments, such as @racket[+], inlining works for two or more
arguments (except for @racket[-], whose one-argument case is also
inlined) when the arguments are either all fixnums or all flonums.

Flonums are typically @defterm{boxed}, which means that memory is
allocated to hold every result of a flonum computation. Fortunately,
the generational garbage collector (described later in
@secref["gc-perf"]) makes allocation for short-lived results
reasonably cheap. Fixnums, in contrast are never boxed, so they are
typically cheap to use.

@margin-note{See @secref["effective-futures"] for an example use of
@tech{flonum}-specific operations.}

The @racketmodname[racket/flonum] library provides flonum-specific
operations, and combinations of flonum operations allow the compiler
to generate code that avoids boxing and unboxing intermediate
results. Besides results within immediate combinations,
flonum-specific results that are bound with @racket[let] and consumed
by a later flonum-specific operation are unboxed within temporary
storage. @margin-note*{Unboxing applies most reliably to uses of a
flonum-specific operation with two arguments.}
Finally, the compiler can detect some flonum-valued loop
accumulators and avoid boxing of the accumulator.
@margin-note*{Unboxing of local bindings and accumulators is not
supported by the @tech{BC} implementation's JIT for PowerPC.}

For some loop patterns, the compiler may need hints to enable
unboxing. For example:

@racketblock[
(define (flvector-sum vec init)
  (let loop ([i 0] [sum init])
    (if (fx= i (flvector-length vec))
        sum
        (loop (fx+ i 1) (fl+ sum (flvector-ref vec i))))))
]

The compiler may not be able to unbox @racket[sum] in this example for
two reasons: it cannot determine locally that its initial value from
@racket[init] will be a flonum, and it cannot tell locally that the
@racket[eq?] identity of the result @racket[sum] is irrelevant.
Changing the reference @racket[init] to @racket[(fl+ init)] and
changing the result @racket[sum] to @racket[(fl+ sum)] gives the
compiler hints and license to unbox @racket[sum].

The bytecode decompiler (see @secref[#:doc '(lib
"scribblings/raco/raco.scrbl") "decompile"]) for the @tech{BC} implementation
annotates combinations where the JIT can avoid boxes with
@racketidfont{#%flonum}, @racketidfont{#%as-flonum}, and
@racketidfont{#%from-flonum}. For the @tech{CS} variant, the
``bytecode'' decompiler shows machine code, but install the
@filepath{disassemble} package to potentially see the machine code as
machine-specific assembly code. See also @refsecref["compiler-inspect"].

The @racketmodname[racket/unsafe/ops] library provides unchecked
fixnum- and flonum-specific operations. Unchecked flonum-specific
operations allow unboxing, and sometimes they allow the compiler to
reorder expressions to improve performance. See also
@secref["unchecked-unsafe"], especially the warnings about unsafety.

@; ----------------------------------------------------------------------

@section[#:tag "unchecked-unsafe"]{Unchecked, Unsafe Operations}

The @racketmodname[racket/unsafe/ops] library provides functions that
are like other functions in @racketmodname[racket/base], but they
assume (instead of checking) that provided arguments are of the right
type. For example, @racket[unsafe-vector-ref] accesses an element from
a vector without checking that its first argument is actually a vector
and without checking that the given index is in bounds. For tight
loops that use these functions, avoiding checks can sometimes speed
the computation, though the benefits vary for different unchecked
functions and different contexts.

Beware that, as ``unsafe'' in the library and function names suggest,
misusing the exports of @racketmodname[racket/unsafe/ops] can lead to
crashes or memory corruption.

@; ----------------------------------------------------------------------

@section[#:tag "ffi-pointer-access"]{Foreign Pointers}

The @racketmodname[ffi/unsafe] library provides functions for unsafely
reading and writing arbitrary pointer values. The compiler recognizes uses
of @racket[ptr-ref] and @racket[ptr-set!] where the second argument is
a direct reference to one of the following built-in C types:
@racket[_int8], @racket[_int16], @racket[_int32], @racket[_int64],
@racket[_double], @racket[_float], and @racket[_pointer]. Then, if the
first argument to @racket[ptr-ref] or @racket[ptr-set!] is a C pointer
(not a byte string), then the pointer read or write is performed
inline in the generated code.

The bytecode compiler will optimize references to integer
abbreviations like @racket[_int] to C types like
@racket[_int32]---where the representation sizes are constant across
platforms---so the compiler can specialize access with those C types. C
types such as @racket[_long] or @racket[_intptr] are not constant
across platforms, so their uses are not as consistently specialized.

Pointer reads and writes using @racket[_float] or @racket[_double] are
not currently subject to unboxing optimizations.

@; ----------------------------------------------------------------------

@section[#:tag "regexp-perf"]{Regular Expression Performance}

When a string or byte string is provided to a function like
@racket[regexp-match], then the string is internally compiled into
a @tech{regexp} value. Instead of supplying a string or byte string
multiple times as a pattern for matching, compile the pattern once to
a @tech{regexp} value using @racket[regexp], @racket[byte-regexp],
@racket[pregexp], or @racket[byte-pregexp]. In place of a constant
string or byte string, write a constant @tech{regexp} using an
@litchar{#rx} or @litchar{#px} prefix.

@racketblock[
(define (slow-matcher str)
  (regexp-match? "[0-9]+" str))

(define (fast-matcher str)
  (regexp-match? #rx"[0-9]+" str))

(define (make-slow-matcher pattern-str)
  (lambda (str)
    (regexp-match? pattern-str str)))

(define (make-fast-matcher pattern-str)
  (define pattern-rx (regexp pattern-str))
  (lambda (str)
    (regexp-match? pattern-rx str)))
]

@; ----------------------------------------------------------------------

@section[#:tag "gc-perf"]{Memory Management}

The @tech{CS} (default) and @tech{BC} Racket
@seclink["virtual-machines"]{virtual machines} each use a modern,
@deftech{generational garbage collector} that makes allocation
relatively cheap for short-lived objects. The @tech{CGC} variant of @tech{BC} uses
a @deftech{conservative garbage collector} which facilitates
interaction with C code at the expense of both precision and speed for
Racket memory management.

Although memory allocation is reasonably cheap, avoiding allocation
altogether is often faster. One particular place where allocation
can be avoided sometimes is in @deftech{closures}, which are the
run-time representation of functions that contain free variables.
For example,

@racketblock[
(let loop ([n 40000000] [prev-thunk (lambda () #f)])
  (if (zero? n)
      (prev-thunk)
      (loop (sub1 n)
            (lambda () n))))
]

allocates a closure on every iteration, since @racket[(lambda () n)]
effectively saves @racket[n].

The compiler can eliminate many closures automatically. For example,
in

@racketblock[
(let loop ([n 40000000] [prev-val #f])
  (let ([prev-thunk (lambda () n)])
    (if (zero? n)
        prev-val
        (loop (sub1 n) (prev-thunk)))))
]

no closure is ever allocated for @racket[prev-thunk], because its only
application is visible, and so it is inlined. Similarly, in 

@racketblock[
(let n-loop ([n 400000])
  (if (zero? n)
      'done
      (let m-loop ([m 100])
        (if (zero? m)
            (n-loop (sub1 n))
            (m-loop (sub1 m))))))
]

then the expansion of the @racket[let] form to implement
@racket[m-loop] involves a closure over @racket[n], but the compiler
automatically converts the closure to pass itself @racket[n] as an
argument instead.

@section[#:tag "Reachability and Garbage Collection"]{Reachability and Garbage Collection}

In general, Racket re-uses the storage for a value when the garbage
collector can prove that the object is unreachable from any other
(reachable) value. Reachability is a low-level, abstraction-breaking
concept, and thus it requires detailed knowledge of the runtime system
to predict exactly when values are reachable from each other. But
generally one value is reachable from a second one when there is some
operation to recover the original value from the second one.

To help programmers understand when an object is no longer reachable and its
storage can be reused,
Racket provides @racket[make-weak-box] and @racket[weak-box-value],
the creator and accessor for a one-record struct that the garbage
collector treats specially. An object inside a weak box does not count
as reachable, and so @racket[weak-box-value] might return the object
inside the box, but it might also return @racket[#f] to indicate
that the object was otherwise unreachable and garbage collected.
Note that unless a garbage collection actually occurs, the value will
remain inside the weak box, even if it is unreachable.

For example, consider this program:
@racketmod[racket
           (struct fish (weight color) #:transparent)
           (define f (fish 7 'blue))
           (define b (make-weak-box f))
           (printf "b has ~s\n" (weak-box-value b))
           (collect-garbage)
           (printf "b has ~s\n" (weak-box-value b))]
It will print @litchar{b has #(struct:fish 7 blue)} twice because the
definition of @racket[f] still holds onto the fish. If the program
were this, however:
@racketmod[racket
           (struct fish (weight color) #:transparent)
           (define f (fish 7 'blue))
           (define b (make-weak-box f))
           (printf "b has ~s\n" (weak-box-value b))
           (set! f #f)
           (collect-garbage)
           (printf "b has ~s\n" (weak-box-value b))]
the second printout will be @litchar{b has #f} because
no reference to the fish exists (other than the one in the box).

As a first approximation, all values in Racket must be allocated and will
demonstrate behavior similar to the fish above. 
There are a number of exceptions, however:
@itemlist[@item{Small integers (recognizable with @racket[fixnum?]) are
                always available without explicit
                allocation. From the perspective of the garbage collector
                and weak boxes, their storage is never reclaimed. (Due to
                clever representation techniques, however, their storage
                does not count towards the space that Racket uses.
                That is, they are effectively free.)}
         @item{Procedures where
               the compiler can see all of their call sites may never be
               allocated at all (as discussed above). 
               Similar optimizations may also eliminate 
               the allocation for other kinds of values.}
         @item{Interned symbols are allocated only once (per place). A table inside
               Racket tracks this allocation so a symbol may not become garbage
               because that table holds onto it.}
         @item{Reachability is only approximate with the @tech{CGC} collector (i.e.,
               a value may appear reachable to that collector when there is,
               in fact, no way to reach it anymore).}]

@section{Weak Boxes and Testing}

One important use of weak boxes is in testing that some abstraction properly 
releases storage for data it no longer needs, but there is a gotcha that 
can easily cause such test cases to pass improperly. 

Imagine you're designing a data structure that needs to
hold onto some value temporarily but then should clear a field or
somehow break a link to avoid referencing that value so it can be
collected. Weak boxes are a good way to test that your data structure
properly clears the value. That is, you might write a test case
that builds a value, extracts some other value from it
(that you hope becomes unreachable), puts the extracted value into a weak-box,
and then checks to see if the value disappears from the box.

This code is one attempt to follow that pattern, but it has a subtle bug:
@racketmod[racket
           (let* ([fishes (list (fish 8 'red)
                                (fish 7 'blue))]
                  [wb (make-weak-box (list-ref fishes 0))])
             (collect-garbage)
             (printf "still there? ~s\n" (weak-box-value wb)))]
Specifically, it will show that the weak box is empty, but not
because @racket[_fishes] no longer holds onto the value, but
because @racket[_fishes] itself is not reachable anymore!

Change the program to this one:
@racketmod[racket
           (let* ([fishes (list (fish 8 'red)
                                (fish 7 'blue))]
                  [wb (make-weak-box (list-ref fishes 0))])
             (collect-garbage)
             (printf "still there? ~s\n" (weak-box-value wb))
             (printf "fishes is ~s\n" fishes))]
and now we see the expected result. The difference is that last
occurrence of the variable @racket[_fishes]. That constitutes
a reference to the list, ensuring that the list is not itself
garbage collected, and thus the red fish is not either.


@section{Reducing Garbage Collection Pauses}

By default, Racket's @tech{generational garbage collector} creates
brief pauses for frequent @deftech{minor collections}, which inspect
only the most recently allocated objects, and long pauses for infrequent
@deftech{major collections}, which re-inspect all memory.

For some applications, such as animations and games,
long pauses due to a major collection can interfere
unacceptably with a program's operation. To reduce major-collection
pauses, the @tech{3m} garbage collector supports @deftech{incremental
garbage-collection} mode, and the @tech{CS} garbage collector supports
a useful approximation:

@itemlist[

@item{In @tech{3m}'s incremental mode, minor collections create longer
      (but still relatively short) pauses by performing extra work
      toward the next major collection. If all goes well, most of a
      major collection's work has been performed by minor collections
      the time that a major collection is needed, so the major
      collection's pause is as short as a minor collection's pause.
      Incremental mode tends to run more slowly overall, but it can
      provide much more consistent real-time behavior.}

@item{In @tech{CS}'s incremental mode, objects are never promoted out
      of the category of ``recently allocated,'' although there are
      degrees of ``recently'' so that most minor collections can still
      skip recent-but-not-too-recent objects. In the common case that
      most of the memory use for animation or game is allocated on
      startup (including its code and the code of the Racket runtime
      system), a major collection may never become necessary.}

]

If the @envvar{PLT_INCREMENTAL_GC} environment variable is set to a
value that starts with @litchar{0}, @litchar{n}, or @litchar{N} when
Racket starts, incremental mode is permanently disabled. For
@tech{3m}, if the @envvar{PLT_INCREMENTAL_GC} environment variable is
set to a value that starts with @litchar{1}, @litchar{y}, or
@litchar{Y} when Racket starts, incremental mode is permanently
enabled. Since incremental mode is only useful for certain parts of
some programs, however, and since the need for incremental mode is a
property of a program rather than its environment, the preferred way
to enable incremental mode is with @racket[(collect-garbage
'incremental)].

Calling @racket[(collect-garbage 'incremental)] does not perform an
immediate garbage collection, but instead requests that each minor
collection perform incremental work up to the next major collection
(unless incremental model is permanently disabled). The request
expires with the next major collection. Make a call to
@racket[(collect-garbage 'incremental)] in any repeating task within
an application that needs to be responsive in real time. Force a full
collection with @racket[(collect-garbage)] just before an initial
@racket[(collect-garbage 'incremental)] to initiate incremental mode
from an optimal state.

To check whether incremental mode is in use and how it affects pause
times, enable @tt{debug}-level logging output for the
@racketidfont{GC} topic. For example,

@commandline{racket -W "debug@"@"GC error" main.rkt}

runs @filepath{main.rkt} with garbage-collection logging to stderr
(while preserving @tt{error}-level logging for all topics). Minor
collections are reported by @litchar{min} lines, increment-mode minor
collections on @tech{3m} are reported with @litchar{mIn} lines, and major
collections are reported with @litchar{MAJ} lines.
