#lang racket/base

(require "core.rkt"
         "basic.rkt"
         "search.rkt"
         "private/manual-sprop.rkt"
         "private/on-demand.rkt"
         "html-properties.rkt"
         "racket-nc.rkt"
         racket/contract
         file/convertible
         racket/extflonum
         (for-syntax racket/base))
  
(provide 
 (contract-out
  (to-element
   (-> any/c any/c any/c any/c
       element?))
  (to-element/no-color
   (-> any/c any/c any/c
       element?))
  (to-paragraph
   (-> any/c any/c any/c any/c (element? . -> . element?)
       block?))
  (to-paragraph/prefix
   (-> any/c any/c any/c any/c any/c any/c any/c (element? . -> . element?)
       block?))
  (syntax-ize
   (->* (any/c (or/c exact-nonnegative-integer? #f)) ((or/c exact-positive-integer? #f) #:expr? boolean?)
        syntax?))
  (syntax-ize-hook
   (parameter/c (-> any/c (or/c exact-nonnegative-integer? #f) (or/c #f syntax?))))
  (current-keyword-list
   (parameter/c (listof symbol?)))
  (current-variable-list
   (parameter/c (listof symbol?)))
  (current-meta-list
   (parameter/c (listof symbol?))))

 define-code

 (contract-out
  (input-color style?)
  (output-color style?)
  (input-background-color style?)
  (no-color style?)
  (reader-color style?)
  (result-color style?)
  (keyword-color style?)
  (comment-color style?)
  (paren-color style?)
  (meta-color style?)
  (value-color style?)
  (symbol-color style?)
  (variable-color style?)
  (opt-color style?)
  (error-color style?)
  (syntax-link-color style?)
  (value-link-color style?)
  (syntax-def-color style?)
  (value-def-color style?)
  (module-color style?)
  (module-link-color style?)
  (block-color style?)
  (highlighted-color style?))

 (struct-out var-id)
 (struct-out shaped-parens)
 (struct-out long-boolean)
 (struct-out just-context)
 (struct-out alternate-display)
 (struct-out literal-syntax)
 (for-syntax make-variable-id
             variable-id?
             make-element-id-transformer
             element-id-transformer?))

(module id-element racket/base
  (require (submod "racket-nc.rkt" id-element))
  (provide make-id-element))

