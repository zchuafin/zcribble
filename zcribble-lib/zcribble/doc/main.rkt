#lang racket/base
(define-syntax-rule (out)
  (begin (require zcribble/doclang)
         (provide (all-from-out zcribble/doclang))))
(out)
