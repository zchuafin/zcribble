#lang zcribble/doc
@(require "mz.rkt"
          (for-label racket/async-channel))

@(define eventspaces @tech[#:doc '(lib "scribblings/gui/gui.scrbl")]{eventspaces})

@title[#:tag "custodians"]{Custodians}

See @secref["custodian-model"] for basic information on the Racket
custodian model.

@defproc[(custodian? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{custodian} value,
@racket[#f] otherwise.}


@defproc[(make-custodian [cust (and/c custodian? (not/c custodian-shut-down?))
                               (current-custodian)])
         custodian?]{

Creates a new custodian that is subordinate to @racket[cust]. When
@racket[cust] is directed (via @racket[custodian-shutdown-all]) to
shut down all of its managed values, the new subordinate custodian is
automatically directed to shut down its managed values as well.}


@defproc[(custodian-shutdown-all [cust custodian?]) void?]{

@margin-note{In @racketmodname[racket/gui/base],
             @|eventspaces| managed by @racket[cust] are also
             shut down.}

Closes all @tech{file-stream ports}, @tech{TCP ports}, @tech{TCP
listeners}, and @tech{UDP sockets} that are managed by @racket[cust]
(and its subordinates), and empties all @tech{custodian box}es
associated with @racket[cust] (and its subordinates). It also removes
@racket[cust] (and its subordinates) as managers of all threads; when
a thread has no managers, it is killed (or suspended; see
@racket[thread/suspend-to-kill]) If the current thread is to be
killed, all other shut-down actions take place before killing the
thread.

If @racket[cust] is already shut down, then
@racket[custodian-shutdown-all] has no effect. When a custodian is
shut down and it has subordinate custodians, the subordinates are not
only shut down, they no longer count as subordinates.}


@defproc[(custodian-shut-down? [cust custodian?]) boolean?]{

Returns @racket[#t] if @racket[cust] has been shut down with
@racket[custodian-shutdown-all] or if it was a subordinate of a
custodian that is shut down, @racket[#f] otherwise.

@history[#:added "6.11.0.5"]}


@defparam[current-custodian cust custodian?]{

@margin-note{Custodians also manage @|eventspaces|
             from @racketmodname[racket/gui/base].}

A @tech{parameter} that determines a custodian that assumes responsibility
for newly created threads, @tech{file-stream ports}, TCP ports,
@tech{TCP listeners}, @tech{UDP sockets}, and @tech{byte converters}.}


@defproc[(custodian-managed-list [cust custodian?] [super custodian?]) list?]{

Returns a list of immediately managed objects (not including
@tech{custodian box}es) and subordinate custodians for @racket[cust],
where @racket[cust] is itself subordinate to @racket[super] (directly
or indirectly). If @racket[cust] is not strictly subordinate to
@racket[super], the @exnraise[exn:fail:contract].

If @racket[cust] has been shut down, the result is @racket['()]. If
@racket[cust] was a subordinate of a custodian that was shut
down, then it cannot be a subordinate of @racket[super].}


@defproc[(custodian-memory-accounting-available?) boolean?]{

@margin-note{Memory accounting is normally available, but not in
the @tech{CGC} implementation.}

Returns @racket[#t] if Racket is compiled with support for
per-custodian memory accounting, @racket[#f] otherwise.}


@defproc[(custodian-require-memory [limit-cust custodian?]
                                   [need-amt exact-nonnegative-integer?]
                                   [stop-cust custodian?]) void?]{

Registers a required-memory check if Racket is compiled with
support for per-custodian memory accounting, otherwise the
@exnraise[exn:fail:unsupported].

If a check is registered, and if Racket later reaches a state after
garbage collection (see @secref["gc-model"]) where allocating
@racket[need-amt] bytes charged to @racket[limit-cust] would fail or
trigger some shutdown, then @racket[stop-cust] is shut down.

The @racket[stop-cust] must be a subordinate custodian of
@racket[limit-cust].}


@defproc[(custodian-limit-memory [limit-cust custodian?]
                                 [limit-amt exact-nonnegative-integer?]
                                 [stop-cust custodian? limit-cust]) void?]{

Registers a limited-memory check if Racket is compiled with
support for per-custodian memory accounting, otherwise the
@exnraise[exn:fail:unsupported].

If a check is registered, and if Racket later reaches a state
after garbage collection (see @secref["gc-model"]) where
@racket[limit-cust] owns more than @racket[limit-amt] bytes, then
@racket[stop-cust] is shut down.

@margin-note{A custodian's limit is checked only after a garbage
             collection, except that it may also be checked during
             certain large allocations that are individually larger
             than the custodian's limit. A single garbage collection
             may shut down multiple custodians, even if shutting down
             only one of the custodians would have reduced memory use
             for other custodians.}

For reliable shutdown, @racket[limit-amt] for
@racket[custodian-limit-memory] must be much lower than the total
amount of memory available (minus the size of memory that is
potentially used and not charged to @racket[limit-cust]). Moreover, if
individual allocations that are initially charged to
@racket[limit-cust] can be arbitrarily large, then @racket[stop-cust]
must be the same as @racket[limit-cust], so that excessively large
immediate allocations can be rejected with an
@racket[exn:fail:out-of-memory] exception.

@margin-note{New memory allocation will be accounted to the running
 @seclink["threads"]{thread}'s managing custodian. In other words, a custodian's limit applies
 only to the allocation made by the threads that it manages.
 See also @racket[call-in-nested-thread] for a simpler setup.}

@examples[
 (require racket/async-channel)
 (define ch (make-async-channel))
 (eval:alts
  (parameterize ([current-custodian (make-custodian)])
    (thread-wait
     (thread
      (λ ()
        (with-handlers ([exn:fail:out-of-memory?
                         (λ (e) (async-channel-put ch e))])
          (custodian-limit-memory (current-custodian) (* 1024 1024))
          (make-bytes (* 4 1024 1024))
          (async-channel-put ch "Not OK")))))
    (async-channel-get ch))
   (exn:fail:out-of-memory "out of memory" (current-continuation-marks)))
 (define cust (make-custodian))
 (eval:alts
   (with-handlers ([exn:fail:out-of-memory?
                    (λ (e) (error "Caught OOM exn"))])
     (call-in-nested-thread
      (λ ()
        (custodian-limit-memory cust (* 1024 1024))
        (make-bytes (* 4 1024 1024))
        "Not OK")
      cust))
   (eval:error
    (error "Caught OOM exn")))
 ]

@examples[
 #:label "Non-examples:"
 (eval:alts
  (parameterize ([current-custodian (make-custodian)])
    (custodian-limit-memory (current-custodian) (* 1024 1024))
    (code:comment @#,elem{Allocation of @racket[make-bytes] is charged to the current thread's})
    (code:comment @#,elem{managing custodian, not the new custodian.})
    (make-bytes (* 4 1024 1024))
    "Not OK")
   "Not OK")
 ]
}

@defproc[(make-custodian-box [cust custodian?] [v any/c]) custodian-box?]{

Returns a @tech{custodian box} that contains @racket[v] as long as
@racket[cust] has not been shut down. If @racket[cust] is already
shut down, the custodian box's value is immediately removed.

A @tech{custodian box} is a @tech{synchronizable event} (see @secref["sync"]).
The @tech{custodian box} becomes ready when its custodian is shut down;
@resultItself{@tech{custodian box}}.}


@defproc[(custodian-box? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{custodian box} produced
by @racket[make-custodian-box], @racket[#f] otherwise.}


@defproc[(custodian-box-value [cb custodian-box?]) any]{

Returns the value in the given @tech{custodian box}, or @racket[#f] if
the value has been removed.}
