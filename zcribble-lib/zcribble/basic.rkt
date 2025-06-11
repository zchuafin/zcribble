#lang racket/base

(require "base.rkt"
         "core.rkt"
         "decode.rkt"
         racket/contract)

(provide title
         section
         subsection
         subsubsection
         subsubsub*section
         include-section

         author
         author+email

         intern-taglet
         module-path-index->taglet
         module-path-prefix->string

         hspace
         elem
         italic bold smaller
         tt
         subscript superscript

         section-index index index* as-index index-section
         get-index-entries index-block

         table-of-contents
         local-table-of-contents)

(provide
 (contract-out
  (itemize
   (->* () (#:style (or/c style? string? symbol? #f)) #:rest (listof (or/c whitespace? items/c)) itemization?))))

(provide
 (contract-out
  (aux-elem
   (->* () () #:rest (listof pre-content?) element?))))

(provide
 (contract-out
  (span-class
   (->* (style-name string?) () #:rest (listof any/c) element?))))

(define (span-class classname . str)
  (make-element classname (decode-content str)))

(define (aux-elem . s)
  (make-element (make-style #f (list 'aux)) (decode-content s)))

(define (itemize #:style [style #f] . items)
  (let ([items (filter (lambda (v) (not (whitespace? v))) items)])
    (apply itemlist #:style style items)))

