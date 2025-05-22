#lang racket/base
(require "private/provide-structs.rkt"
         racket/serialize
         racket/contract/base
         xml/xexpr
         net/url-structs)
(provide
 (all-defined-out))

(define-serializable-struct body-id (value) #:transparent)
(define-serializable-struct document-source (module-path) #:transparent)
(define-serializable-struct xexpr-property (before after) #:transparent)
(define-serializable-struct hover-property (text) #:transparent)
(define-serializable-struct script-property (type script) #:transparent)
(define-serializable-struct css-addition (path) #:transparent)
(define-serializable-struct js-addition (path) #:transparent)
(define-serializable-struct html-defaults (prefix-path style-path extra-files) #:transparent)
(define-serializable-struct css-style-addition (path) #:transparent)
(define-serializable-struct js-style-addition (path) #:transparent)
(define-serializable-struct url-anchor (name) #:transparent)
(define-serializable-struct alt-tag (name) #:transparent)
(define-serializable-struct attributes (assoc) #:transparent)
(define-serializable-struct column-attributes (assoc) #:transparent)
(define-serializable-struct part-link-redirect [url] #:transparent)
(define-serializable-struct part-title-and-content-wrapper (tag attribs) #:transparent)
(define-serializable-struct install-resource (path) #:transparent)
(define-serializable-struct link-resource (path) #:transparent)
(define-serializable-struct head-extra (xexpr) #:transparent)
(define-serializable-struct head-addition (xexpr) #:transparent)
(define-serializable-struct render-convertible-as (types) #:transparent)