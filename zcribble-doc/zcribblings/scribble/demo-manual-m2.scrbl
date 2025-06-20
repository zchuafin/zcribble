#lang racket/base
(require "demo-manual.scrbl"
         zcribble/core
         zcribble/manual)

(define renamed-doc
  (struct-copy part doc
               [style manual-doc-style]
               [title-content
                (cons "M2 " (part-title-content doc))]))

(provide (rename-out [renamed-doc doc]))
