#lang zcribble/doc
@(require "mz.rkt")

@title[#:tag "port-ops"]{Managing Ports}

@defproc[(input-port? [v any/c]) boolean?]{
Returns @racket[#t] if @racket[v] is an @tech{input port}, @racket[#f] otherwise.}

@defproc[(output-port? [v any/c]) boolean?]{
Returns @racket[#t] if @racket[v] is an @tech{output port}, @racket[#f] otherwise.}

@defproc[(port? [v any/c]) boolean?]{
Returns @racket[#t] if either @racket[(input-port? v)] or
@racket[(output-port? v)] is @racket[#t], @racket[#f] otherwise.}

@defproc[(close-input-port [in input-port?]) void?]{
Closes the input port @racket[in]. For some kinds of ports, closing
the port releases lower-level resources, such as a file handle. If
the port is already closed, @racket[close-input-port] has no effect.}

@defproc[(close-output-port [out output-port?]) void?]{
Closes the output port @racket[out]. For some kinds of ports, closing
the port releases lower-level resources, such as a file handle. Also,
if the port is buffered, closing may first flush the port before
closing it, and this flushing process can block. If the port is
already closed, @racket[close-output-port] has no effect.}

@defproc[(port-closed? [port port?]) boolean?]{
Returns @racket[#t] if the input or output port @racket[port] is
closed, @racket[#f] otherwise.}

@defproc[(port-closed-evt [port port?]) evt?]{
Return a @tech{synchronizable event} that becomes @tech{ready for
synchronization} when @racket[port] is
closed. @ResultItself{port-closed event}.}

@defparam[current-input-port in input-port?]{A @tech{parameter} that
determines a default input port for many operations, such as
@racket[read].}

@defparam[current-output-port out output-port?]{A @tech{parameter} that
determines a default output port for many operations, such as
@racket[write].}

@defparam[current-error-port out output-port?]{A @tech{parameter} that
determines an output port that is typically used for errors and
logging. For example, the default error display handler writes to this
port.}

@defproc[(file-stream-port? [v any/c]) boolean?]{
Returns @racket[#t] if @racket[v] is a @tech{file-stream port} (see
@secref["file-ports"]), @racket[#f] otherwise.

@history[#:changed "7.2.0.5" @elem{Extended @racket[file-stream-port?]
                                   to any value, instead of resticting
                                   the domain to ports}]}

@defproc[(terminal-port? [v any/c]) boolean?]{
Returns @racket[#t] if @racket[v] is a port that is attached to an
interactive terminal, @racket[#f] otherwise.

@history[#:changed "7.2.0.5" @elem{Extended @racket[terminal-port?]
                                   to any value, instead of resticting
                                   the domain to ports}]}


@defproc[(port-waiting-peer? [port port?]) boolean?]{

Returns @racket[#t] if @racket[port] is not ready for reading or
writing because it is waiting for a peer process to complete a stream
construction, @racket[#f] otherwise.

On Unix and Mac OS, opening a fifo for output creates a peer-waiting
port if no reader for the same fifo is already opened. In that case,
the output port is not ready for writing until a reader is opened;
that is, write opertaions will block. Use @racket[sync] if necessary
to wait until writing will not block---that is, until the read end of
the fifo is opened.

@history[#:added "7.4.0.5"]}



@defthing[eof eof-object?]{A value (distinct from all other values)
that represents an end-of-file.}

@defproc[(eof-object? [v any/c]) boolean?]{Returns @racket[#t] if
@racket[v] is @racket[eof], @racket[#f] otherwise.}
