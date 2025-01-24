#lang racket/base

(require "manual.rkt" "struct.rkt" "scheme.rkt" "decode.rkt" "eval-nc.rkt"
         (only-in "core.rkt" content? plain)
         racket/contract/base
         racket/file
         racket/list
         file/convertible ;; attached into new namespace via anchor
         racket/serialize ;; attached into new namespace via anchor
         racket/pretty ;; attached into new namespace via anchor
         scribble/private/serialize ;; attached into new namespace via anchor
         racket/sandbox racket/promise racket/port
         racket/gui/dynamic
         (for-syntax racket/base syntax/srcloc racket/struct)
         racket/stxparam
         racket/splicing
         racket/string
         scribble/text/wrap)

(provide
 interaction
 interaction0
 interaction/no-prompt
 interaction-eval
 interaction-eval-show
 schemeblock+eval
 racketblock0+eval
 schememod+eval
 def+int
 defs+int
 examples
 examples*
 defexamples
 defexamples*
 (contract-out
  [make-base-eval
   (->* [] [#:pretty-print? any/c #:lang lang-option/c] #:rest any/c any)]
 [make-base-eval-factory
  eval-factory/c]
 [make-eval-factory
  eval-factory/c]
 [close-eval
  (-> any/c any)]
         
 [scribble-exn->string
  (parameter/c (-> any/c string?))]
 [scribble-eval-handler
  (parameter/c (-> (-> any/c any) boolean? any/c any))]
 [make-log-based-eval
  (-> path-string? (or/c 'record 'replay) any)]))

(define lang-option/c
  (or/c module-path? (list/c 'special symbol?) (cons/c 'begin list?)))

(define eval-factory/c
  (->* [(listof module-path?)] [#:pretty-print? any/c #:lang lang-option/c] any))

(provide
 (contract-out
  (as-examples
   (case->
    (-> block? block?)
    (-> (or/c block? content?) block? block?)))))

(module+ test
  (require rackunit)
  (test-case
   "eval:check in interaction"
   (check-not-exn (λ () (interaction (eval:check #t #t))))))









