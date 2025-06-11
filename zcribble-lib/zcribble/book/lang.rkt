#lang racket/base
(require zcribble/doclang
         zcribble/base
         "../private/defaults.rkt"
         zcribble/latex-prefix)

(provide (except-out (all-from-out zcribble/doclang) #%module-begin)
         (all-from-out zcribble/base)
         (rename-out [module-begin #%module-begin]))

(define-syntax-rule (module-begin id . body)
  (#%module-begin id (post-process) () . body))

(define ((post-process) doc)
  (add-defaults doc
                (string->bytes/utf-8 (string-append "\\documentclass{book}\n"
                                                    unicode-encoding-packages))
                (scribble-file "book/style.tex")
                null
                #f))
