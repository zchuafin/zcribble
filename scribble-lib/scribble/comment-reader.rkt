#lang racket/base

(require (only-in racket/port peeking-input-port)
         "comment-reader-nc.rkt"
         racket/contract)

(provide
 (contract-out
  [read
   (->* () (input-port?) any/c)]
  [read-syntax
   (->* (any/c) (input-port?) any/c)]
  [make-comment-readtable
   (->* () (#:readtable (or/c #false readtable?))
            readtable?)]))