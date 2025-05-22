#lang racket/base

(require "struct-nc.rkt"
         "basic.rkt"
         "search-nc.rkt"
         racket/contract
         syntax/modcode
         racket/phase+space)

(provide
 (contract-out
  (find-racket-tag
   (->* (part? resolve-info? any/c (or/c exact-integer? #f))
       (#:space space? #:suffix space? #:unlinked-ok? any/c)
       (or/c tag? #f))) ; not sure if tag? is correct
  (find-scheme-tag
   (->* (part? resolve-info? any/c (or/c exact-integer? #f))
       (#:space space? #:suffix space? #:unlinked-ok? any/c)
       (or/c tag? #f)))))

