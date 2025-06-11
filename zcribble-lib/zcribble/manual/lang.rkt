#lang racket/base
(require zcribble/doclang 
         zcribble/manual
         zcribble/html-properties
         "../private/manual-defaults.rkt")
(provide (except-out (all-from-out zcribble/doclang) #%module-begin)
         (all-from-out zcribble/manual)
         (rename-out [module-begin #%module-begin])
         manual-doc-style)

(define-syntax-rule (module-begin id . body)
  (#%module-begin id post-process () . body))
