#lang racket/base

(require "base.rkt"
         "core.rkt"
         "basic-nc.rkt"
         "decode.rkt"
         racket/contract)

(provide
 ;; precontent? and an-item? is not used?
 (contract-out
  (span-class
   (->* (string?) #:rest (listof any/c) element?))
   (aux-elem
    (-> any/c element?))
   (itemize
    (->* () (#:style (or/c style? string? symbol? #f)) #:rest (listof (or/c whitespace? any/c))
         itemization?)))
 
 title
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
         
 item item?

 hspace
 elem
 italic bold smaller
 tt
 subscript superscript

 section-index index index* as-index index-section
 get-index-entries index-block

 table-of-contents
 local-table-of-contents)
