#lang racket/base
(require "core-nc.rkt"
         "private/provide-structs.rkt"
         racket/serialize
         racket/contract/base)

(define-serializable-struct module-path-index-desc ())
(define-serializable-struct (language-index-desc module-path-index-desc) ())
(define-serializable-struct (reader-index-desc module-path-index-desc) ())
(define-serializable-struct exported-index-desc (name from-libs))
(define-serializable-struct (method-index-desc exported-index-desc) (method-name class-tag))
(define-serializable-struct (constructor-index-desc exported-index-desc) (class-tag))
(define-serializable-struct (procedure-index-desc exported-index-desc) ())
(define-serializable-struct (thing-index-desc exported-index-desc) ())
(define-serializable-struct (struct-index-desc exported-index-desc) ())
(define-serializable-struct (form-index-desc exported-index-desc) ())
(define-serializable-struct (class-index-desc exported-index-desc) ())
(define-serializable-struct (interface-index-desc exported-index-desc) ())
(define-serializable-struct (mixin-index-desc exported-index-desc) ())

