#lang racket

(require
  "bnf-nc.rkt"
  scribble/decode
  (except-in scribble/struct
             element?)
  (only-in scribble/core
           content?
           element?
           make-style
           make-table-columns)
  )

(provide (contract-out
          [BNF (-> (cons/c (or/c block? content?)
                           (non-empty-listof (or/c block? content?)))
                   ...
                   table?)]
          [BNF-etc element?]
          ;; operate on content
          [BNF-seq (-> content? ...
                       (or/c element? ""))]
          [BNF-seq-lines (-> (listof content?) ...
                             block?)]
          [BNF-alt (-> content? ...
                       element?)]
          [BNF-alt/close (-> content? ...
                             element?)]
          ;; operate on pre-content
          [BNF-group (-> pre-content? ...
                         element?)]
          [nonterm (-> pre-content? ...
                       element?)]
          [optional (-> pre-content? ...
                        element?)]
          [kleenestar (-> pre-content? ...
                          element?)]
          [kleeneplus (-> pre-content? ...
                          element?)]
          [kleenerange (-> any/c any/c pre-content? ...
                           element?)]
          ))