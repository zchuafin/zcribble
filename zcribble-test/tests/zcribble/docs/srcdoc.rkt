#lang racket
(require zcribble/srcdoc
         (for-doc racket/base
                  zcribble/manual))

(provide
 (proc-doc f (-> integer?) ["Stuff"])
 (form-doc #:id a #:literals (foo) (expr foo a) ["Returns " (racket expr) "."]))

(define (f) 5)

(define-syntax-rule (a x) x)
