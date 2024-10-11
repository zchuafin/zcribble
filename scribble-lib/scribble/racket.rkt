#lang racket/base

(require "core.rkt"
         "basic.rkt"
         "search.rkt"
         "private/manual-sprop.rkt"
         "private/on-demand.rkt"
         "html-properties.rkt"
         "racket-nc.rkt"
         file/convertible
         racket/extflonum
         (for-syntax racket/base))
  
(provide define-code
         to-element
         to-element/no-color
         to-paragraph
         to-paragraph/prefix
         syntax-ize
         syntax-ize-hook
         current-keyword-list
         current-variable-list
         current-meta-list

         input-color
         output-color
         input-background-color
         no-color
         reader-color
         result-color
         keyword-color
         comment-color
         paren-color
         meta-color
         value-color
         symbol-color
         variable-color
         opt-color
         error-color
         syntax-link-color
         value-link-color
         syntax-def-color
         value-def-color
         module-color
         module-link-color
         block-color
         highlighted-color

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

