#lang racket/base

(provide valid-blueboxes-info?)

(require zcribble/core racket/contract/base)

(define valid-blueboxes-info?
  (hash/c
   tag?
   (listof (cons/c exact-nonnegative-integer?
                   exact-nonnegative-integer?))
   #:flat? #t))
