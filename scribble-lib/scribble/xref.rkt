#lang racket/base

(require "struct-nc.rkt"
         "xref-nc.rkt"
         racket/contract
         (only-in scribble/core known-doc? known-doc-v)
         scribble/base-render
         scribble/search
         (prefix-in html: scribble/html-render)
         racket/class
         racket/path
         racket/list)

(provide
 (contract-out
  (load-xref
   (->* ((listof (-> (or/c any/c (-> list?)))))
        (#:demand-source-for-use (-> any/c symbol? (or/c (-> any/c) #f)) ;; looks like there is a bug got '(exporting-packages #f) instead of tag?
         #:demand-source (-> tag? (or/c (-> any/c) #f))
         #:render% (implementation?/c render<%>)
         #:root (or/c path-string? false/c)
         #:doc-id (or/c path-string? false/c))
         xref?))
  (xref?
   (-> any/c boolean?))
  (xref-render
   (->* (xref? part? (or/c path-string? false/c)
        #:render% (implementation?/c render<%>) ;; implementation was spelled wrong
        #:refer-to-existing-files? any/c)
        (or/c void? any/c)))
  (xref-index
   (-> xref? (listof entry?)))
  (xref-binding->definition-tag
   (-> xref?
       (or/c identifier?
             (list/c (or/c module-path?
                           module-path-index?)
                     symbol?)
             (list/c module-path-index?
                     symbol?
                     module-path-index?
                     symbol?
                     (one-of/c 0 1)
                     (or/c exact-integer? false/c)
                     (or/c exact-integer? false/c))
             (list/c (or/c module-path?
                           module-path-index?)
                     symbol?
                     (one-of/c 0 1)
                     (or/c exact-integer? false/c)
                     (or/c exact-integer? false/c)))
       (or/c exact-integer? false/c)
       (or/c tag? false/c)))
 (xref-tag->path+anchor
  (->* (xref?
        tag?
        #:external-root-url (or/c string? #f)
        #:render% (implementation?/c render<%>))
       (values (or/c false/c path?) (or/c false/c string?)))) ;; more?
 (xref-tag->index-entry
  (-> xref? tag? (or/c false/c entry?)))
 (xref-transfer-info
  (-> (is-a?/c render<%>) collect-info? xref? void?))
 (struct
   entry
    ((words (and/c (listof string?) cons?))
     (content list?)
     (tag tag?)
     (desc any/c)))
 (make-data+root
  (-> any/c (or/c #f path-string?) data+root?))
 (data+root?
  (-> any/c boolean?))
 (make-data+root+doc-id
  (-> any/c (or/c #f path-string?) string? data+root+doc-id?))
 (data+root+doc-id?
  (-> any/c boolean?))))