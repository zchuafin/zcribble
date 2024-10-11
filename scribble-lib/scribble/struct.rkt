#lang racket/base
(require
  "struct-nc.rkt"
  (only-in "core-nc.rkt" element-style? content?)
  racket/provide-syntax
  racket/struct-info
  racket/contract/base
  (for-syntax racket/base))

(provide
 (contract-out
 [struct with-attributes ([style any/c]
                          [assoc (listof (cons/c symbol? string?))])]
 [struct image-file ([path (or/c path-string?
                                 (cons/c (one-of/c 'collects)
                                         (listof bytes?)))]
                     [scale real?])]
 [struct target-url ([addr path-string?] [style any/c])]
 [struct element ([style element-style?] [content content?])]
 [make-flow (-> (listof block?) (listof block?))]
 [flow? (-> any/c boolean?)]
 [flow-paragraphs (-> (listof block?) (listof block?))]))
